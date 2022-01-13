/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <qglobal.h>

namespace Occ {

/***********************************************************
Possible permissions, must match the server permission constants
***********************************************************/
enum SharePermission {
    SharePermissionRead     = 1 << 0,
    SharePermissionUpdate   = 1 << 1,
    SharePermissionCreate   = 1 << 2,
    SharePermissionDelete   = 1 << 3,
    SharePermissionShare    = 1 << 4,
    SharePermissionDefault  = 1 << 30
};
Q_DECLARE_FLAGS (SharePermissions, SharePermission)
Q_DECLARE_OPERATORS_FOR_FLAGS (SharePermissions)

} // namespace Occ

#endif
