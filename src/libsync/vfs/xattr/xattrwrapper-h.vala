/*
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/
// #pragma once

// #include <QString>

namespace Occ {

namespace XAttrWrapper {

OWNCLOUDSYNC_EXPORT bool hasNextcloudPlaceholderAttributes (QString &path);
OWNCLOUDSYNC_EXPORT Result<void, QString> addNextcloudPlaceholderAttributes (QString &path);

}

} // namespace Occ
