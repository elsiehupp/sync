/***********************************************************
@author Roeland Jago Douma <rullzer@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
Possible permissions, must match the server permission constants
***********************************************************/
enum Share_permission {
    SharePermissionRead     = 1 << 0,
    Share_permission_update   = 1 << 1,
    Share_permission_create   = 1 << 2,
    Share_permission_delete   = 1 << 3,
    Share_permission_share    = 1 << 4,
    Share_permission_default  = 1 << 30
}
// Q_DECLARE_FLAGS (Share.Permissions, Share_permission)
// Q_DECLARE_OPERATORS_FOR_FLAGS (Share.Permissions)

} // namespace Occ

//  #endif
