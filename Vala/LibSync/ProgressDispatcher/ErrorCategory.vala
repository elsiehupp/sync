/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Progress {

/***********************************************************
Type of error

Used for Progress_dispatcher.sync_error. May trigger error interactivity
in IssuesWidget.
***********************************************************/
enum ErrorCategory {
    Normal,
    InsufficientRemoteStorage,
}

} // namespace Progress
} // namespace Occ
