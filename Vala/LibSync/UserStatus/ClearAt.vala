/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

// TODO: If we can use C++17 make it a std.variant
struct ClearAt {
    enum ClearAtType {
        Period,
        EndOf,
        Timestamp
    }

    ClearAtType this.type = ClearAtType.Period;

    uint64 this.timestamp;
    int this.period;
    string this.endof;
};