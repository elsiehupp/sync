namespace Occ {
namespace Testing {

/***********************************************************
@class TestSearchTermResultsNotFound

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSearchTermResultsNotFound : AbstractTestUnifiedSearchListmodel {

    /***********************************************************
    ***********************************************************/
    private TestSearchTermResultsNotFound () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "[empty]");

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, UnifiedSearchResultsListModel.is_search_in_progress_changed);

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (search_in_progress_changed.length == 1);
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        GLib.assert_true (model.row_count () == 0);
    }

} // class TestSearchTermResultsNotFound

} // namespace Testing
} // namespace Occ
