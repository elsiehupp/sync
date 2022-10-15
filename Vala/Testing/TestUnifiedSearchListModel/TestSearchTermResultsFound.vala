namespace Occ {
namespace Testing {

/***********************************************************
@class TestSearchTermResultsFound

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSearchTermResultsFound : AbstractTestUnifiedSearchListmodel {

    /***********************************************************
    ***********************************************************/
    private TestSearchTermResultsFound () {
        //  // make sure the model is empty
        //  model.set_search_term ("");
        //  GLib.assert_true (model.row_count () == 0);

        //  // test that search term gets set, search gets started and enough results get returned
        //  model.set_search_term (model.search_term () + "discuss");

        //  GLib.SignalSpy search_in_progress_changed = new GLib.SignalSpy (
        //      model, UnifiedSearchResultsListModel.is_search_in_progress_changed);

        //  GLib.assert_true (search_in_progress_changed.wait ());

        //  // make sure search has started
        //  GLib.assert_true (search_in_progress_changed.length == 1);
        //  GLib.assert_true (model.is_search_in_progress ());

        //  GLib.assert_true (search_in_progress_changed.wait ());

        //  // make sure search has finished
        //  GLib.assert_true (!model.is_search_in_progress ());

        //  GLib.assert_true (model.row_count () > 0);
    }

} // class TestSearchTermResultsFound

} // namespace Testing
} // namespace Occ
