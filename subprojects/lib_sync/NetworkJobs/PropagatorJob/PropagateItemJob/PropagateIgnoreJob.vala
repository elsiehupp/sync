namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateIgnoreJob

@brief Dummy job that just mark it as completed and ignored

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateIgnoreJob : AbstractPropagateItemJob {

    //  /***********************************************************
    //  ***********************************************************/
    //  public PropagateIgnoreJob (OwncloudPropagator propagator, SyncFileItem item) {
    //      base (propagator, item);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public new void start () {
    //      SyncFileItem.Status status = this.item.status;
    //      if (status == SyncFileItem.Status.NO_STATUS) {
    //          if (this.item.instruction == CSync.SyncInstructions.ERROR) {
    //              status = SyncFileItem.Status.NORMAL_ERROR;
    //          } else {
    //              status = SyncFileItem.Status.FILE_IGNORED;
    //              //  GLib.assert_true (this.item.instruction == CSync.SyncInstructions.IGNORE);
    //          }
    //      }
    //      on_signal_done (status, this.item.error_string);
    //  }

} // class PropagateIgnoreJob

} // namespace LibSync
} // namespace Occ
