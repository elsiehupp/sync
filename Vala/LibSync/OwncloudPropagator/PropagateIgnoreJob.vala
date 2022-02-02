
/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
class PropagateIgnoreJob : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateIgnoreJob (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateItemJob (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override {
        SyncFileItem.Status status = this.item._status;
        if (status == SyncFileItem.Status.NO_STATUS) {
            if (this.item._instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.Status.NORMAL_ERROR;
            } else {
                status = SyncFileItem.Status.FILE_IGNORED;
                ASSERT (this.item._instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        on_done (status, this.item._error_string);
    }
};