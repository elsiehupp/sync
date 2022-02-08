/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

// TODO: If we can use C++17 make it a std.variant
class ClearAt {
    enum ClearAtType {
        Period,
        EndOf,
        Timestamp
    }

    ClearAtType type = ClearAtType.Period;

    uint64 timestamp;
    int period;
    string endof;
}

} // namespace Occ