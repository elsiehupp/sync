/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
class PropagateIgnoreJob : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateIgnoreJob (OwncloudPropagator propagator, SyncFileItemPtr item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        SyncFileItem.Status status = this.item.status;
        if (status == SyncFileItem.Status.NO_STATUS) {
            if (this.item.instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.Status.NORMAL_ERROR;
            } else {
                status = SyncFileItem.Status.FILE_IGNORED;
                //  ASSERT (this.item.instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        on_done (status, this.item.error_string);
    }

} // class PropagateIgnoreJob

} // namespace Occ
