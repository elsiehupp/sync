namespace Occ {
namespace Testing {

/***********************************************************
@class TestSearchTermStartStopSearch

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSearchTermStartStopSearch : AbstractTestUnifiedSearchListmodel {

//    /***********************************************************
//    ***********************************************************/
//    private TestSearchTermStartStopSearch () {
//        // make sure the model is empty
//        model.set_search_term ("");
//        GLib.assert_true (model.row_count () == 0);

//        // #1 test set_search_term actually sets the search term and the signal is emitted
//        GLib.SignalSpy search_term_changed = new GLib.SignalSpy (model, UnifiedSearchResultsListModel.search_term_changed);
//        model.set_search_term ("dis");
//        GLib.assert_true (search_term_changed.length == 1);
//        GLib.assert_true (model.search_term () == "dis");

//        // #2 test set_search_term actually sets the search term and the signal is emitted
//        search_term_changed = "";
//        model.set_search_term (model.search_term () + "cuss");
//        GLib.assert_true (model.search_term () == "discuss");
//        GLib.assert_true (search_term_changed.length == 1);

//        // #3 test that model has not started search yet
//        GLib.assert_true (!model.is_search_in_progress ());

//        // #4 test that model has started the search after specific delay
//        GLib.SignalSpy search_in_progress_changed = new GLib.SignalSpy (model, UnifiedSearchResultsListModel.is_search_in_progress_changed);
//        // allow search jobs to get created within the model
//        GLib.assert_true (search_in_progress_changed.wait ());
//        GLib.assert_true (search_in_progress_changed.length == 1);
//        GLib.assert_true (model.is_search_in_progress ());

//        // #5 test that model has stopped the search after setting empty search term
//        model.set_search_term ("");
//        GLib.assert_true (!model.is_search_in_progress ());
//    }

} // class TestSearchTermStartStopSearch

} // namespace Testing
} // namespace Occ
