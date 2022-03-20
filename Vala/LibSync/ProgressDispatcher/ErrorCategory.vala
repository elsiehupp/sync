/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {
namespace Progress {

/***********************************************************
Type of error

Used for ProgressDispatcher.signal_sync_error. May trigger error interactivity
in IssuesWidget.
***********************************************************/
enum ErrorCategory {
    NORMAL,
    INSUFFICIENT_REMOTE_STORAGE,
}

} // namespace Progress
} // namespace LibSync
} // namespace Occ
