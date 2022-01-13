/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <string>

namespace Occ {

namespace XAttrWrapper {

OWNCLOUDSYNC_EXPORT bool hasNextcloudPlaceholderAttributes (string &path);
OWNCLOUDSYNC_EXPORT Result<void, string> addNextcloudPlaceholderAttributes (string &path);

}

} // namespace Occ
