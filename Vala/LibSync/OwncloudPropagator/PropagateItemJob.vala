
/***********************************************************
Abstract class to propagate a single item
***********************************************************/
class PropagateItemJob : PropagatorJob {

    protected virtual void on_done (SyncFileItem.Status status, string error_string = "");


    /***********************************************************
    set a custom restore job message that is used if the restore job succeeded.
    It is displayed in the activity view.
    ***********************************************************/
    protected string restore_job_msg () {
        return this.item._is_restoration ? this.item._error_string : "";
    }
    protected void set_restore_job_msg (string msg = "") {
        this.item._is_restoration = true;
        this.item._error_string = msg;
    }

    protected bool has_encrypted_ancestor ();

protected slots:
    void on_restore_job_finished (SyncFileItem.Status status);


    /***********************************************************
    ***********************************************************/
    private QScopedPointer<PropagateItemJob> this.restore_job;
    private JobParallelism this.parallelism;


    /***********************************************************
    ***********************************************************/
    public PropagateItemJob (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagatorJob (propagator)
        , this.parallelism (FullParallelism)
        , this.item (item) {
        // we should always execute jobs that process the E2EE API calls as sequential jobs
        // TODO : In fact, we must make sure Lock/Unlock are not colliding and always wait for each other to complete. So, we could refactor this "this.parallelism" later
        // so every "PropagateItemJob" that will potentially execute Lock job on E2EE folder will get executed sequentially.
        // As an alternative, we could optimize Lock/Unlock calls, so we do a batch-write on one folder and only lock and unlock a folder once per batch.
        this.parallelism = (this.item._is_encrypted || has_encrypted_ancestor ()) ? WaitForFinished : FullParallelism;
    }
    ~PropagateItemJob () override;

    /***********************************************************
    ***********************************************************/
    public bool on_schedule_self_or_child () override {
        if (this.state != NotYetStarted) {
            return false;
        }
        q_c_info (lc_propagator) << "Starting" << this.item._instruction << "propagation of" << this.item.destination () << "by" << this;

        this.state = Running;
        QMetaObject.invoke_method (this, "on_start"); // We could be in a different thread (neon jobs)
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public JobParallelism parallelism () override {
        return this.parallelism;
    }


    /***********************************************************
    ***********************************************************/
    public SyncFileItemPtr this.item;

    /***********************************************************
    ***********************************************************/
    public 
    public virtual void on_start ();
}


PropagateItemJob.~PropagateItemJob () {
    if (var p = propagator ()) {
        // Normally, every job should clean itself from the this.active_job_list. So this should not be
        // needed. But if a job has a bug or is deleted before the network jobs signal get received,
        // we might risk end up with dangling pointer in the list which may cause crashes.
        p._active_job_list.remove_all (this);
    }
}



void PropagateItemJob.on_done (SyncFileItem.Status status_arg, string error_string) {
    // Duplicate calls to on_done () are a logic error
    ENFORCE (this.state != Finished);
    this.state = Finished;

    this.item._status = status_arg;

    if (this.item._is_restoration) {
        if (this.item._status == SyncFileItem.Status.SUCCESS
            || this.item._status == SyncFileItem.Status.CONFLICT) {
            this.item._status = SyncFileItem.Status.RESTORATION;
        } else {
            this.item._error_string += _("; Restoration Failed : %1").arg (error_string);
        }
    } else {
        if (this.item._error_string.is_empty ()) {
            this.item._error_string = error_string;
        }
    }

    if (propagator ()._abort_requested && (this.item._status == SyncFileItem.Status.NORMAL_ERROR
                                          || this.item._status == SyncFileItem.Status.FATAL_ERROR)) {
        // an on_abort request is ongoing. Change the status to Soft-Error
        this.item._status = SyncFileItem.Status.SOFT_ERROR;
    }

    // Blocklist handling
    switch (this.item._status) {
    case SyncFileItem.Status.SOFT_ERROR:
    case SyncFileItem.Status.FATAL_ERROR:
    case SyncFileItem.Status.NORMAL_ERROR:
    case SyncFileItem.Status.DETAIL_ERROR:
        // Check the blocklist, possibly adjusting the item (including its status)
        blocklist_update (propagator ()._journal, this.item);
        break;
    case SyncFileItem.Status.SUCCESS:
    case SyncFileItem.Status.RESTORATION:
        if (this.item._has_blocklist_entry) {
            // wipe blocklist entry.
            propagator ()._journal.wipe_error_blocklist_entry (this.item._file);
            // remove a blocklist entry in case the file was moved.
            if (this.item._original_file != this.item._file) {
                propagator ()._journal.wipe_error_blocklist_entry (this.item._original_file);
            }
        }
        break;
    case SyncFileItem.Status.CONFLICT:
    case SyncFileItem.Status.FILE_IGNORED:
    case SyncFileItem.Status.NO_STATUS:
    case SyncFileItem.Status.BLOCKLISTED_ERROR:
    case SyncFileItem.Status.FILE_LOCKED:
    case SyncFileItem.Status.FILENAME_INVALID:
        // nothing
        break;
    }

    if (this.item.has_error_status ())
        GLib.warn (lc_propagator) << "Could not complete propagation of" << this.item.destination () << "by" << this << "with status" << this.item._status << "and error:" << this.item._error_string;
    else
        q_c_info (lc_propagator) << "Completed propagation of" << this.item.destination () << "by" << this << "with status" << this.item._status;
    /* emit */ propagator ().item_completed (this.item);
    /* emit */ finished (this.item._status);

    if (this.item._status == SyncFileItem.Status.FATAL_ERROR) {
        // Abort all remaining jobs.
        propagator ().on_abort ();
    }
}

void PropagateItemJob.on_restore_job_finished (SyncFileItem.Status status) {
    string msg;
    if (this.restore_job) {
        msg = this.restore_job.restore_job_msg ();
        this.restore_job.set_restore_job_msg ();
    }

    if (status == SyncFileItem.Status.SUCCESS || status == SyncFileItem.Status.CONFLICT
        || status == SyncFileItem.Status.RESTORATION) {
        on_done (SyncFileItem.Status.SOFT_ERROR, msg);
    } else {
        on_done (status, _("A file or folder was removed from a read only share, but restoring failed : %1").arg (msg));
    }
}

bool PropagateItemJob.has_encrypted_ancestor () {
    if (!propagator ().account ().capabilities ().client_side_encryption_available ()) {
        return false;
    }

    const var path = this.item._file;
    const var slash_position = path.last_index_of ('/');
    const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

    var path_components = parent_path.split ('/');
    while (!path_components.is_empty ()) {
        SyncJournalFileRecord record;
        propagator ()._journal.get_file_record (path_components.join ('/'), record);
        if (record.is_valid () && record._is_e2e_encrypted) {
            return true;
        }
        path_components.remove_last ();
    }

    return false;
}
