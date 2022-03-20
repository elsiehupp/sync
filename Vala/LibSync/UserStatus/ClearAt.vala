/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

// TODO: If we can use C++17 make it a std.variant
public class ClearAt : GLib.Object {
    enum ClearAtType {
        Period,
        EndOf,
        Timestamp
    }

    ClearAtType type = ClearAtType.Period;

    uint64 timestamp;
    int period;
    string endof;

} // class ClearAt

} // namespace LibSync
} // namespace Occ