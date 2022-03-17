/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QAbstractItemModelTester>
//  #include <QDesktopServices>
//  #include <QSignalSpy>
//  #include <QTest>

namespace Testing {

public class TestUnifiedSearchListmodel : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public const int SEARCH_RESULTS_REPLY_DELAY = 100;

    /***********************************************************
    ***********************************************************/
    public FakeQNAM fake_qnam;
    public unowned Occ.Account account;
    public Occ.AccountState account_state;
    public Occ.UnifiedSearchResultsListModel model;
    public QAbstractItemModelTester model_tester;

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler fake_desktop_services_url_handler;

    /***********************************************************
    ***********************************************************/
    //  public TestUnifiedSearchListmodel ();

    /***********************************************************
    ***********************************************************/
    private void on_signal_init_test_case () {
        fake_qnam.on_signal_reset (new FakeQNAM ({}));
        account = Occ.Account.create ();
        account.set_credentials (new FakeCredentials (fake_qnam));
        account.set_url (GLib.Uri ("http://example.de"));

        account_state.on_signal_reset (new Occ.AccountState (account));

        fake_qnam.set_override (
            this.init_test_case_override_delegate
        );

        model.on_signal_reset (new Occ.UnifiedSearchResultsListModel (account_state));

        model_tester.on_signal_reset (new QAbstractItemModelTester (model));

        fake_desktop_services_url_handler.on_signal_reset (new FakeDesktopServicesUrlHandler ());
    }


    private Soup.Reply init_test_case_override_delegate (Soup.Operation operation, Soup.Request request, QIODevice device) {

        Soup.Reply reply = null;

        var url_query = QUrlQuery (request.url ());
        var format = url_query.query_item_value ("format");
        var cursor = url_query.query_item_value ("cursor").to_int ();
        var search_term = url_query.query_item_value ("term");
        var path = request.url ().path ();

        if (!request.url ().to_string ().starts_with (account_state.account.url ().to_string ())) {
            reply = new FakeErrorReply (operation, request, this, 404, FAKE_404_RESPONSE);
        }
        if (format != "json") {
            reply = new FakeErrorReply (operation, request, this, 400, FAKE_400_RESPONSE);
        }

        // handle fetch of providers list
        if (path.starts_with ("/ocs/v2.php/search/providers") && search_term == "") {
            reply = new FakePayloadReply (operation, request,
                FakeSearchResultsStorage.instance.fake_providers_response_json (), fake_qnam);
        // handle search for provider
        } else if (path.starts_with ("/ocs/v2.php/search/providers") && !search_term == "") {
            var path_split = path.mid ("/ocs/v2.php/search/providers".size ())
                                       .split ('/', Qt.SkipEmptyParts);

            if (!path_split == "" && path.contains (path_split.first ())) {
                reply = new FakePayloadReply (operation, request,
                    FakeSearchResultsStorage.instance.query_provider (path_split.first (), search_term, cursor),
                    SEARCH_RESULTS_REPLY_DELAY, fake_qnam);
            }
        }

        if (!reply) {
            return (Soup.Reply)new FakeErrorReply (operation, request, this, 404, "{error : \"Not found!\"}");
        }

        return reply;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_search_term_start_stop_search () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // #1 test set_search_term actually sets the search term and the signal is emitted
        QSignalSpy search_term_changed = new QSignalSpy (model, Occ.UnifiedSearchResultsListModel.search_term_changed);
        model.set_search_term ("dis");
        GLib.assert_true (search_term_changed.count () == 1);
        GLib.assert_true (model.search_term () == "dis");

        // #2 test set_search_term actually sets the search term and the signal is emitted
        search_term_changed.clear ();
        model.set_search_term (model.search_term () + "cuss");
        GLib.assert_true (model.search_term () == "discuss");
        GLib.assert_true (search_term_changed.count () == 1);

        // #3 test that model has not started search yet
        GLib.assert_true (!model.is_search_in_progress ());

        // #4 test that model has started the search after specific delay
        QSignalSpy search_in_progress_changed = new QSignalSpy (model, &Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);
        // allow search jobs to get created within the model
        GLib.assert_true (search_in_progress_changed.wait ());
        GLib.assert_true (search_in_progress_changed.count () == 1);
        GLib.assert_true (model.is_search_in_progress ());

        // #5 test that model has stopped the search after setting empty search term
        model.set_search_term ("");
        GLib.assert_true (!model.is_search_in_progress ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_search_term_results_found () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "discuss");

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (search_in_progress_changed.count () == 1);
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        GLib.assert_true (model.row_count () > 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_search_term_results_not_found () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "[empty]");

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (search_in_progress_changed.count () == 1);
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        GLib.assert_true (model.row_count () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_fetch_more_clicked () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);

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
            model, &Occ.UnifiedSearchResultsListModel.current_fetch_more_in_progress_provider_id_changed);
        QSignalSpy rows_inserted = new QSignalSpy (model, &Occ.UnifiedSearchResultsListModel.rows_inserted);
        for (int i = 0; i < model.row_count (); ++i) {
            var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == Occ.UnifiedSearchResult.Type.FetchMoreTrigger) {
                var provider_id =
                    model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
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

            QSignalSpy rows_removed = new QSignalSpy (model, &Occ.UnifiedSearchResultsListModel.rows_removed);

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
                var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);
                var provider_id =  model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                            .to_string ();
                if (type == Occ.UnifiedSearchResult.Type.FetchMoreTrigger
                    && provider_id == provider_id_fetch_more_triggered) {
                    is_fetch_more_trigger_found = true;
                    break;
                }
            }

            GLib.assert_true (!is_fetch_more_trigger_found);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_search_term_result_tickled () {
        // make sure the model is empty
        model.set_search_term ("");
        GLib.assert_true (model.row_count () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.set_search_term (model.search_term () + "discuss");

        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (search_in_progress_changed.count () == 1);
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
            var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == Occ.UnifiedSearchResult.Type.DEFAULT) {
                var provider_id =
                    model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                        .to_string ();
                url_for_clicked_result = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ResourceUrlRole).to_string ();

                if (!provider_id == "" && !url_for_clicked_result == "") {
                    model.signal_result_clicked (provider_id, GLib.Uri (url_for_clicked_result));
                    break;
                }
            }
        }

        GLib.assert_true (signal_result_clicked.count () == 1);

        var arguments = signal_result_clicked.take_first ();

        var url_open_triggered_via_desktop_services = arguments.at (0).to_string ();

        GLib.assert_true (url_open_triggered_via_desktop_services == url_for_clicked_result);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_search_term_results_error () {
        // make sure the model is empty
        model.set_search_term (QStringLiteral (""));
        GLib.assert_true (model.row_count () == 0);

        QSignalSpy error_string_changed = new QSignalSpy (model, &Occ.UnifiedSearchResultsListModel.error_string_changed);
        QSignalSpy search_in_progress_changed = new QSignalSpy (
            model, &Occ.UnifiedSearchResultsListModel.is_search_in_progress_changed);

        model.set_search_term (model.search_term () + QStringLiteral ("[HTTP500]"));

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has started
        GLib.assert_true (model.is_search_in_progress ());

        GLib.assert_true (search_in_progress_changed.wait ());

        // make sure search has on_signal_finished
        GLib.assert_true (!model.is_search_in_progress ());

        // make sure the model is empty and an error string has been set
        GLib.assert_true (model.row_count () == 0);

        GLib.assert_true (error_string_changed.count () > 0);

        GLib.assert_true (!model.error_string () == "");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup_test_case () {
        FakeSearchResultsStorage.destroy ();
    }

}
}