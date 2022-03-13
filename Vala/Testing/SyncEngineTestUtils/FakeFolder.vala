/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeFolder {

    /***********************************************************
    ***********************************************************/
    public struct ErrorList {

        FakeQNAM qnam;

        void append (string path, int error = 500) {
            this.qnam.error_paths ().insert (path, error);
        }

        void clear () {
            this.qnam.error_paths ().clear ();
        }
    }

    QTemporaryDir temporary_directory;
    DiskFileModifier local_modifier;

    // FIXME: Clarify ownership, double delete
    FakeQNAM fake_qnam;
    Occ.unowned Account account;
    std.unique_ptr<Occ.SyncJournalDb> journal_database;
    std.unique_ptr<Occ.SyncEngine> sync_engine;


    /***********************************************************
    ***********************************************************/
    public FakeFolder (FileInfo template_file_info, Occ.Optional<FileInfo> local_file_info = new Occ.Optional<FileInfo> (), string remote_path = "") {
        this.local_modifier = this.temporary_directory.path ();
        // Needs to be done once
        Occ.SyncEngine.minimum_file_age_for_upload = std.chrono.milliseconds (0);
        Occ.Logger.instance ().set_log_file ("-");
        Occ.Logger.instance ().add_log_rule ({ "sync.httplogger=true" });
    
        QDir root_directory = new QDir (this.temporary_directory.path ());
        GLib.debug ("FakeFolder operating on " + root_directory);
        if (local_file_info) {
            to_disk (root_directory, *local_file_info);
        } else {
            to_disk (root_directory, template_file_info);
        }
    
        this.fake_qnam = new FakeQNAM (template_file_info);
        this.account = Occ.Account.create ();
        this.account.set_url (GLib.Uri ("http://admin:admin@localhost/owncloud"));
        this.account.set_credentials (new FakeCredentials (this.fake_qnam));
        this.account.set_dav_display_name ("fakename");
        this.account.set_server_version ("10.0.0");
    
        this.journal_database = std.make_unique<Occ.SyncJournalDb> (local_path () + ".sync_test.db");
        this.sync_engine = std.make_unique<Occ.SyncEngine> (this.account, local_path (), remote_path, this.journal_database.get ());
        // Ignore temporary files from the download. (This is in the default exclude list, but we don't load it)
        this.sync_engine.excluded_files ().add_manual_exclude ("]*.~*");
    
        // handle about_to_remove_all_files with a timeout in case our test does not handle it
        GLib.Object.connect (this.sync_engine.get (), &Occ.SyncEngine.about_to_remove_all_files, this.sync_engine.get (), [this] (Occ.SyncFileItem.Direction, std.function<void (bool)> callback) {
            QTimer.single_shot (1 * 1000, this.sync_engine.get (), [callback] {
                callback (false);
            });
        });
    
        // Ensure we have a valid VfsOff instance "running"
        switch_to_vfs (this.sync_engine.sync_options ().vfs);
    
        // A new folder will update the local file state database on first sync.
        // To have a state matching what users will encounter, we have to a sync
        // using an identical local/remote file tree first.
        ENFORCE (sync_once ());
    }

    /***********************************************************
    ***********************************************************/
    public void switch_to_vfs (unowned<Occ.Vfs> vfs);

    /***********************************************************
    ***********************************************************/
    public Occ.unowned Account account () {
        return this.account;
    }

    /***********************************************************
    ***********************************************************/
    public Occ.SyncEngine sync_engine () {
        return this.sync_engine;
    }

    /***********************************************************
    ***********************************************************/
    public Occ.SyncJournalDb sync_journal () {
        return this.journal_database;
    }


    /***********************************************************
    ***********************************************************/
    public FileModifier local_modifier () {
        return this.local_modifier;
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo remote_modifier () {
        return this.fake_qnam.current_remote_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo current_local_state ();

    /***********************************************************
    ***********************************************************/
    public FileInfo current_remote_state () {
        return this.fake_qnam.current_remote_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo upload_state () {
        return this.fake_qnam.upload_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo database_state ();

    /***********************************************************
    ***********************************************************/
    public ErrorList server_error_paths () {
        return this.fake_qnam;
    }

    /***********************************************************
    ***********************************************************/
    public void set_server_override (FakeQNAM.Override qnam_override) {
        this.fake_qnam.set_override(qnam_override);
    }

    delegate QJsonObject ReplyFunction (GLib.HashMap<string, GLib.ByteArray> map);

    /***********************************************************
    ***********************************************************/
    public QJsonObject for_each_reply_part (
        QIODevice outgoing_data,
        string content_type,
        ReplyFunction reply_function) {
        return this.fake_qnam.for_each_reply_part (outgoing_data, content_type, reply_function);
    }

    /***********************************************************
    ***********************************************************/
    public string local_path ();

    /***********************************************************
    ***********************************************************/
    public void schedule_sync ();

    /***********************************************************
    ***********************************************************/
    public void exec_until_before_propagation ();

    /***********************************************************
    ***********************************************************/
    public void exec_until_item_completed (string relative_path);

    /***********************************************************
    ***********************************************************/
    public bool exec_until_finished () {
        QSignalSpy spy = new QSignalSpy (this.sync_engine.get (), SIGNAL (on_signal_finished (bool)));
        bool ok = spy.wait (3600000);
        GLib.assert_true (ok && "Sync timed out");
        return spy[0][0].to_bool ();
    }

    /***********************************************************
    ***********************************************************/
    public bool sync_once () {
        schedule_sync ();
        return exec_until_finished ();
    }

    /***********************************************************
    ***********************************************************/
    private static void to_disk (QDir directory, FileInfo template_file_info);

    /***********************************************************
    ***********************************************************/
    private static void from_disk (QDir directory, FileInfo template_file_info);

}
}










void FakeFolder.switch_to_vfs (unowned<Occ.Vfs> vfs) {
    var opts = this.sync_engine.sync_options ();

    opts.vfs.stop ();
    GLib.Object.disconnect (this.sync_engine.get (), null, opts.vfs.data (), null);

    opts.vfs = vfs;
    this.sync_engine.set_sync_options (opts);

    Occ.VfsSetupParams vfs_params;
    vfs_params.filesystem_path = local_path ();
    vfs_params.remote_path = '/';
    vfs_params.account = this.account;
    vfs_params.journal = this.journal_database.get ();
    vfs_params.provider_name = "OC-TEST";
    vfs_params.provider_version = "0.1";
    GLib.Object.connect (
        this.sync_engine.get (),
        GLib.Object.destroyed,
        vfs.data (),
        [vfs] () {
        vfs.stop ();
        vfs.unregister_folder ();
    });

    vfs.on_signal_start (vfs_params);
}

FileInfo FakeFolder.current_local_state () {
    QDir root_directory ( this.temporary_directory.path ());
    FileInfo root_template;
    from_disk (root_directory, root_template);
    root_template.fixup_parent_path_recursively ();
    return root_template;
}

string FakeFolder.local_path () {
    // SyncEngine wants a trailing slash
    if (this.temporary_directory.path ().ends_with ('/'))
        return this.temporary_directory.path ();
    return this.temporary_directory.path () + '/';
}

void FakeFolder.schedule_sync () {
    // Have to be done async, else, an error before exec () does not terminate the event loop.
    QMetaObject.invoke_method (this.sync_engine.get (), "start_sync", Qt.QueuedConnection);
}

void FakeFolder.exec_until_before_propagation () {
    QSignalSpy spy = new QSignalSpy (
        this.sync_engine.get (),
        about_to_propagate (SyncFileItemVector &)
    );
    GLib.assert_true (spy.wait ());
}

void FakeFolder.exec_until_item_completed (string relative_path) {
    QSignalSpy spy = new QSignalSpy (
        this.sync_engine.get (),
        item_completed (SyncFileItemPtr &)
    );
    QElapsedTimer t;
    t.on_signal_start ();
    while (t.elapsed () < 5000) {
        spy.clear ();
        GLib.assert_true (spy.wait ());
        for (GLib.List<GLib.Variant> args : spy) {
            var item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == relative_path)
                return;
        }
    }
    GLib.assert_true (false);
}

void FakeFolder.to_disk (QDir directory, FileInfo template_file_info) {
    foreach (FileInfo child, template_file_info.children) {
        if (child.is_directory) {
            QDir sub_directory = new QDir (directory);
            directory.mkdir (child.name);
            sub_directory.cd (child.name);
            to_disk (sub_directory, child);
        } else {
            GLib.File file = new GLib.File (directory.file_path (child.name));
            file.open (GLib.File.WriteOnly);
            file.write (GLib.ByteArray {}.fill (child.content_char, child.size));
            file.close ();
            Occ.FileSystem.set_modification_time (file.filename (), Occ.Utility.date_time_to_time_t (child.last_modified));
        }
    }
}

void FakeFolder.from_disk (QDir directory, FileInfo template_file_info) {
    foreach (GLib.FileInfo disk_child, directory.entry_info_list (QDir.AllEntries | QDir.NoDotAndDotDot)) {
        if (disk_child.is_directory ()) {
            QDir sub_directory = directory;
            sub_directory.cd (disk_child.filename ());
            FileInfo sub_file_info = template_file_info.children[disk_child.filename ()] = FileInfo ( disk_child.filename ());
            from_disk (sub_directory, sub_file_info);
        } else {
            GLib.File f ( disk_child.file_path ());
            f.open (GLib.File.ReadOnly);
            var content = f.read (1);
            if (content.size () == 0) {
                GLib.warn ("Empty file at:" + disk_child.file_path ();
                continue;
            }
            char content_char = content.at (0);
            template_file_info.children.insert (disk_child.filename (), FileInfo ( disk_child.filename (), disk_child.size (), content_char });
        }
    }
}

static FileInfo find_or_create_directories (FileInfo base, PathComponents components) {
    if (components.is_empty ())
        return base;
    var child_name = components.path_root ();
    var it = base.children.find (child_name);
    if (it != base.children.end ()) {
        return find_or_create_directories (*it, components.sub_components ());
    }
    var new_directory = base.children[child_name] = FileInfo ( child_name };
    new_directory.parent_path = base.path ();
    return find_or_create_directories (new_directory, components.sub_components ());
}

FileInfo FakeFolder.database_state () {
    FileInfo result;
    this.journal_database.get_files_below_path ("", [&] (Occ.SyncJournalFileRecord record) {
        var components = PathComponents (record.path ());
        var parent_directory = find_or_create_directories (result, components.parent_directory_components ());
        var name = components.filename ();
        var item = parent_directory.children[name];
        item.name = name;
        item.parent_path = parent_directory.path ();
        item.size = record.file_size;
        item.is_directory = record.type == ItemTypeDirectory;
        item.permissions = record.remote_perm;
        item.etag = record.etag;
        item.last_modified = Occ.Utility.date_time_from_time_t (record.modtime);
        item.file_identifier = record.file_identifier;
        item.checksums = record.checksum_header;
        // item.content_char can't be set from the database
    });
    return result;
}