/***********************************************************
@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
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
    public PropagateIgnoreJob (OwncloudPropagator propagator, SyncFileItem item) {
        base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        SyncFileItem.Status status = this.item.status;
        if (status == SyncFileItem.Status.NO_STATUS) {
            if (this.item.instruction == CSync.SyncInstructions.ERROR) {
                status = SyncFileItem.Status.NORMAL_ERROR;
            } else {
                status = SyncFileItem.Status.FILE_IGNORED;
                //  ASSERT (this.item.instruction == CSync.SyncInstructions.IGNORE);
            }
        }
        on_signal_done (status, this.item.error_string);
    }

} // class PropagateIgnoreJob

} // namespace LibSync
} // namespace Occ
