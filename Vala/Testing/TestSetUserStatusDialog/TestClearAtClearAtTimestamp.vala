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
        new TestClearAtClearAtTimestamp2 (current_time);
        new TestClearAtClearAtTimestamp3 (current_time);
        new TestClearAtClearAtTimestamp4 (current_time);
        new TestClearAtClearAtTimestamp5 (current_time);
        new TestClearAtClearAtTimestamp6 (current_time);
        new TestClearAtClearAtTimestamp7 (current_time);
        new TestClearAtClearAtTimestamp8 (current_time);
    }

} // class TestClearAtClearAtTimestamp

} // namespace Testing
} // namespace Occ
