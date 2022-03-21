namespace Occ {
namespace Testing {

/***********************************************************
@class TestSearchTermResultsError

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSearchTermResultsError : AbstractTestUnifiedSearchListmodel {

    /***********************************************************
    ***********************************************************/
    private TestSearchTermResultsError () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        QSignalSpy error_string_changed = new QSignalSpy (model, &UnifiedSearchResultsListModel.error_string_changed);
        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, &UnifiedSearchResultsListModel.is_search_in_progress_changed);

        model.set_search_term (model.search_term () + "[HTTP500]");

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        // make sure the model is empty and an error string has been set
        GLib.assert_true (model.row_count () == 0);

        GLib.assert_true (error_string_changed.count () > 0);

        GLib.assert_true (!model.error_string == "");
    }

} // class TestSearchTermResultsError

} // namespace Testing
} // namespace Occ
