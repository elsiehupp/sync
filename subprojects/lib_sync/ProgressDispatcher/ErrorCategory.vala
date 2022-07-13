/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {
namespace Progress {

/***********************************************************
@enum ErrorCategory

@brief Type of error.

Used for ProgressDispatcher.signal_sync_error. May trigger
error interactivity in IssuesWidget.

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public enum ErrorCategory {

    NORMAL,
    INSUFFICIENT_REMOTE_STORAGE,

} // enum ErrorCategory

} // namespace Progress
} // namespace LibSync
} // namespace Occ
