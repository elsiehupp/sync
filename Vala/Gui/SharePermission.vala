/***********************************************************
@author Roeland Jago Douma <rullzer@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
Possible permissions, must match the server permission constants
***********************************************************/
internal enum SharePermission {
    READ     = 1 << 0,
    UPDATE   = 1 << 1,
    CREATE   = 1 << 2,
    DELETE   = 1 << 3,
    SHARE    = 1 << 4,
    DEFAULT  = 1 << 30
} // enum SharePermission

} // namespace Ui
} // namespace Occ

//  #endif
