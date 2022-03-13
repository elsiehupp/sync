/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {
namespace Progress {

/***********************************************************
Type of error

Used for ProgressDispatcher.sync_error. May trigger error interactivity
in IssuesWidget.
***********************************************************/
enum ErrorCategory {
    NORMAL,
    INSUFFICIENT_REMOTE_STORAGE,
}

} // namespace Progress
} // namespace LibSync
} // namespace Occ
