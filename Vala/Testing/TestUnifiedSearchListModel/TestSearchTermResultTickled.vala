namespace Occ {
namespace Testing {

/***********************************************************
@class TestSearchTermResultTickled

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestSearchTermResultTickled : AbstractTestUnifiedSearchListmodel {

    /***********************************************************
    ***********************************************************/
    private TestSearchTermResultTickled () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "discuss");

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, UnifiedSearchResultsListModel.is_search_in_progress_changed);

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (search_in_progress_changed.length == 1);
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished and some results has been received
        GLib.assert_true (!model.is_search_in_progress ());

        GLib.assert_true (model.row_count () != 0);

        QDesktopServices.set_url_handler ("http", fake_desktop_services_url_handler, "signal_result_clicked");
        QDesktopServices.set_url_handler ("https", fake_desktop_services_url_handler, "signal_result_clicked");

        QSignalSpy signal_result_clicked = new QSignalSpy (fake_desktop_services_url_handler, &FakeDesktopServicesUrlHandler.signal_result_clicked);

        //  test click on a result item
        string url_for_clicked_result;

        for (int i = 0; i < model.row_count (); ++i) {
            var type = model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == UnifiedSearchResult.Type.DEFAULT) {
                var provider_id =
                    model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                        .to_string ();
                url_for_clicked_result = model.data (model.index (i), UnifiedSearchResultsListModel.DataRole.ResourceUrlRole).to_string ();

                if (provider_id != "" && url_for_clicked_result != "") {
                    model.signal_result_clicked (provider_id, GLib.Uri (url_for_clicked_result));
                    break;
                }
            }
        }

        GLib.assert_true (signal_result_clicked.length == 1);

        var arguments = signal_result_clicked.take_first ();

        var url_open_triggered_via_desktop_services = arguments.at (0).to_string ();

        GLib.assert_true (url_open_triggered_via_desktop_services == url_for_clicked_result);
    }

} // class TestSearchTermResultTickled

} // namespace Testing
} // namespace Occ
