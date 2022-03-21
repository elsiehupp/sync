namespace Occ {
namespace Testing {

/***********************************************************
@class TestFetchMoreClicked

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestFetchMoreClicked : AbstractTestUnifiedSearchListmodel {

    /***********************************************************
    ***********************************************************/
    private TestFetchMoreClicked () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, UnifiedSearchResultsListModel.is_search_in_progress_changed);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "whatever");

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        var number_of_rows_in_mmodel_previous = model.row_count ();

        // test fetch more results
        QSignalSpy current_fetch_more_in_progress_provider_id_changed = new QSignalSpy (
            model, &UnifiedSearchResultsListModel.current_fetch_more_in_progress_provider_id_changed);
        QSignalSpy rows_inserted = new QSignalSpy (model, &UnifiedSearchResultsListModel.rows_inserted);
        for (int i = 0; i < model.row_count (); ++i) {
            var type = model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == UnifiedSearchResult.Type.FetchMoreTrigger) {
                var provider_id =
                    model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                        .to_string ();
                model.fetch_more_trigger_clicked (provider_id);
                break;
            }
        }

        // make sure the current_fetch_more_in_progress_provider_id was set back and forth and correct number fows has been inserted
        GLib.assert_true (current_fetch_more_in_progress_provider_id_changed.count () == 1);

        var provider_id_fetch_more_triggered = model.current_fetch_more_in_progress_provider_id ();

        GLib.assert_true (!provider_id_fetch_more_triggered == "");

        GLib.assert_true (current_fetch_more_in_progress_provider_id_changed.wait ());

        GLib.assert_true (model.current_fetch_more_in_progress_provider_id () == "");

        GLib.assert_true (rows_inserted.count () == 1);

        var arguments = rows_inserted.take_first ();

        GLib.assert_true (arguments.size () > 0);

        var first = arguments.at (0).to_int ();
        var last = arguments.at (1).to_int ();

        const int number_of_inserted_expected = last - first;

        GLib.assert_true (model.row_count () - number_of_rows_in_mmodel_previous == number_of_inserted_expected);

        // make sure the FetchMoreTrigger gets removed when no more results available
        if (!provider_id_fetch_more_triggered == "") {
            current_fetch_more_in_progress_provider_id_changed.clear ();
            rows_inserted.clear ();

            QSignalSpy rows_removed = new QSignalSpy (model, &UnifiedSearchResultsListModel.rows_removed);

            for (int i = 0; i < 10; ++i) {
                model.fetch_more_trigger_clicked (provider_id_fetch_more_triggered);

                GLib.assert_true (current_fetch_more_in_progress_provider_id_changed.wait ());

                if (rows_removed.count () > 0) {
                    break;
                }
            }

            GLib.assert_true (rows_removed.count () == 1);

            bool is_fetch_more_trigger_found = false;

            for (int i = 0; i < model.row_count (); ++i) {
                var type = model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.TypeRole);
                var provider_id =  model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                            .to_string ();
                if (type == UnifiedSearchResult.Type.FetchMoreTrigger
                    && provider_id == provider_id_fetch_more_triggered) {
                    is_fetch_more_trigger_found = true;
                    break;
                }
            }

            GLib.assert_true (!is_fetch_more_trigger_found);
        }
    }

} // class TestFetchMoreClicked

} // namespace Testing
} // namespace Occ
