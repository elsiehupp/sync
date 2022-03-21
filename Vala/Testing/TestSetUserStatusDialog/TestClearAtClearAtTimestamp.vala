/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearAtClearAtTimestamp : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearAtClearAtTimestamp () {
        const GLib.DateTime current_time = create_date_time ();
        TestClearAtClearAtTimestamp2 (current_time);
        TestClearAtClearAtTimestamp3 (current_time);
        TestClearAtClearAtTimestamp4 (current_time);
        TestClearAtClearAtTimestamp5 (current_time);
        TestClearAtClearAtTimestamp6 (current_time);
        TestClearAtClearAtTimestamp7 (current_time);
        TestClearAtClearAtTimestamp8 (current_time);
    }

} // class TestClearAtClearAtTimestamp

} // namespace Testing
} // namespace Occ
