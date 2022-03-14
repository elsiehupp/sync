/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief Dummy job that just mark it as completed and ignored
@ingroup libsync
***********************************************************/
public class PropagateIgnoreJob : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateIgnoreJob (OwncloudPropagator propagator, unowned SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        SyncFileItem.Status status = this.item.status;
        if (status == SyncFileItem.Status.NO_STATUS) {
            if (this.item.instruction == CSYNC_INSTRUCTION_ERROR) {
                status = SyncFileItem.Status.NORMAL_ERROR;
            } else {
                status = SyncFileItem.Status.FILE_IGNORED;
                //  ASSERT (this.item.instruction == CSYNC_INSTRUCTION_IGNORE);
            }
        }
        on_signal_done (status, this.item.error_string);
    }

} // class PropagateIgnoreJob

} // namespace LibSync
} // namespace Occ
