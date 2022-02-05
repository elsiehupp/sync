/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QAbstractItemModelTester>
//  #include <QDesktopServices>
//  #include <QSignalSpy>
//  #include <QTest>

namespace {

}

class TestUnifiedSearchListmodel : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public TestUnifiedSearchListmodel () = default;

    /***********************************************************
    ***********************************************************/
    public QScopedPointer<FakeQNAM> fakeQnam;
    public Occ.AccountPointer account;
    public QScopedPointer<Occ.AccountState> accountState;
    public QScopedPointer<Occ.UnifiedSearchResultsListModel> model;
    public QScopedPointer<QAbstractItemModelTester> modelTester;

    /***********************************************************
    ***********************************************************/
    public QScopedPointer<FakeDesktopServicesUrlHandler> fakeDesktopServicesUrlHandler;

    /***********************************************************
    ***********************************************************/
    public const int searchResultsReplyDelay = 100;

    /***********************************************************
    ***********************************************************/
    private void on_init_test_case () {
        fakeQnam.on_reset (new FakeQNAM ({}));
        account = Occ.Account.create ();
        account.setCredentials (new FakeCredentials{fakeQnam.data ()});
        account.setUrl (GLib.Uri ( ("http://example.de")));

        accountState.on_reset (new Occ.AccountState (account));

        fakeQnam.setOverride ([this] (QNetworkAccessManager.Operation op, QNetworkRequest req, QIODevice device) {
            //  Q_UNUSED (device);
            Soup.Reply reply = null;

            const var urlQuery = QUrlQuery (req.url ());
            const var format = urlQuery.queryItemValue (QStringLiteral ("format"));
            const var cursor = urlQuery.queryItemValue (QStringLiteral ("cursor")).toInt ();
            const var searchTerm = urlQuery.queryItemValue (QStringLiteral ("term"));
            const var path = req.url ().path ();

            if (!req.url ().toString ().startsWith (accountState.account ().url ().toString ())) {
                reply = new FakeErrorReply (op, req, this, 404, fake404Response);
            }
            if (format != QStringLiteral ("json")) {
                reply = new FakeErrorReply (op, req, this, 400, fake400Response);
            }

            // handle fetch of providers list
            if (path.startsWith (QStringLiteral ("/ocs/v2.php/search/providers")) && searchTerm.isEmpty ()) {
                reply = new FakePayloadReply (op, req,
                    FakeSearchResultsStorage.instance ().fakeProvidersResponseJson (), fakeQnam.data ());
            // handle search for provider
            } else if (path.startsWith (QStringLiteral ("/ocs/v2.php/search/providers")) && !searchTerm.isEmpty ()) {
                const var pathSplit = path.mid (string (QStringLiteral ("/ocs/v2.php/search/providers")).size ())
                                           .split ('/', Qt.SkipEmptyParts);

                if (!pathSplit.isEmpty () && path.contains (pathSplit.first ())) {
                    reply = new FakePayloadReply (op, req,
                        FakeSearchResultsStorage.instance ().queryProvider (pathSplit.first (), searchTerm, cursor),
                        searchResultsReplyDelay, fakeQnam.data ());
                }
            }

            if (!reply) {
                return qobject_cast<Soup.Reply> (new FakeErrorReply (op, req, this, 404, QByteArrayLiteral ("{error : \"Not found!\"}")));
            }

            return reply;
        });

        model.on_reset (new Occ.UnifiedSearchResultsListModel (accountState.data ()));

        modelTester.on_reset (new QAbstractItemModelTester (model.data ()));

        fakeDesktopServicesUrlHandler.on_reset (new FakeDesktopServicesUrlHandler);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_search_term_start_stop_search () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        // #1 test setSearchTerm actually sets the search term and the signal is emitted
        QSignalSpy searhTermChanged (model.data (), &Occ.UnifiedSearchResultsListModel.searchTermChanged);
        model.setSearchTerm (QStringLiteral ("dis"));
        QCOMPARE (searhTermChanged.count (), 1);
        QCOMPARE (model.searchTerm (), QStringLiteral ("dis"));

        // #2 test setSearchTerm actually sets the search term and the signal is emitted
        searhTermChanged.clear ();
        model.setSearchTerm (model.searchTerm () + QStringLiteral ("cuss"));
        QCOMPARE (model.searchTerm (), QStringLiteral ("discuss"));
        QCOMPARE (searhTermChanged.count (), 1);

        // #3 test that model has not started search yet
        QVERIFY (!model.isSearchInProgress ());

        // #4 test that model has started the search after specific delay
        QSignalSpy searchInProgressChanged (model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);
        // allow search jobs to get created within the model
        QVERIFY (searchInProgressChanged.wait ());
        QCOMPARE (searchInProgressChanged.count (), 1);
        QVERIFY (model.isSearchInProgress ());

        // #5 test that model has stopped the search after setting empty search term
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (!model.isSearchInProgress ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_search_term_results_found () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.setSearchTerm (model.searchTerm () + QStringLiteral ("discuss"));

        QSignalSpy searchInProgressChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has started
        QCOMPARE (searchInProgressChanged.count (), 1);
        QVERIFY (model.isSearchInProgress ());

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has on_finished
        QVERIFY (!model.isSearchInProgress ());

        QVERIFY (model.rowCount () > 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_search_term_results_not_found () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.setSearchTerm (model.searchTerm () + QStringLiteral ("[empty]"));

        QSignalSpy searchInProgressChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has started
        QCOMPARE (searchInProgressChanged.count (), 1);
        QVERIFY (model.isSearchInProgress ());

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has on_finished
        QVERIFY (!model.isSearchInProgress ());

        QVERIFY (model.rowCount () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_fetch_more_clicked () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        QSignalSpy searchInProgressChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);

        // test that search term gets set, search gets started and enough results get returned
        model.setSearchTerm (model.searchTerm () + QStringLiteral ("whatever"));

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has started
        QVERIFY (model.isSearchInProgress ());

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has on_finished
        QVERIFY (!model.isSearchInProgress ());

        const var numRowsInModelPrev = model.rowCount ();

        // test fetch more results
        QSignalSpy currentFetchMoreInProgressProviderIdChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.currentFetchMoreInProgressProviderIdChanged);
        QSignalSpy rowsInserted (model.data (), &Occ.UnifiedSearchResultsListModel.rowsInserted);
        for (int i = 0; i < model.rowCount (); ++i) {
            const var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == Occ.UnifiedSearchResult.Type.FetchMoreTrigger) {
                const var providerId =
                    model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                        .toString ();
                model.fetchMoreTriggerClicked (providerId);
                break;
            }
        }

        // make sure the currentFetchMoreInProgressProviderId was set back and forth and correct number fows has been inserted
        QCOMPARE (currentFetchMoreInProgressProviderIdChanged.count (), 1);

        const var providerIdFetchMoreTriggered = model.currentFetchMoreInProgressProviderId ();

        QVERIFY (!providerIdFetchMoreTriggered.isEmpty ());

        QVERIFY (currentFetchMoreInProgressProviderIdChanged.wait ());

        QVERIFY (model.currentFetchMoreInProgressProviderId ().isEmpty ());

        QCOMPARE (rowsInserted.count (), 1);

        const var arguments = rowsInserted.takeFirst ();

        QVERIFY (arguments.size () > 0);

        const var first = arguments.at (0).toInt ();
        const var last = arguments.at (1).toInt ();

        const int numInsertedExpected = last - first;

        QCOMPARE (model.rowCount () - numRowsInModelPrev, numInsertedExpected);

        // make sure the FetchMoreTrigger gets removed when no more results available
        if (!providerIdFetchMoreTriggered.isEmpty ()) {
            currentFetchMoreInProgressProviderIdChanged.clear ();
            rowsInserted.clear ();

            QSignalSpy rowsRemoved (model.data (), &Occ.UnifiedSearchResultsListModel.rowsRemoved);

            for (int i = 0; i < 10; ++i) {
                model.fetchMoreTriggerClicked (providerIdFetchMoreTriggered);

                QVERIFY (currentFetchMoreInProgressProviderIdChanged.wait ());

                if (rowsRemoved.count () > 0) {
                    break;
                }
            }

            QCOMPARE (rowsRemoved.count (), 1);

            bool isFetchMoreTriggerFound = false;

            for (int i = 0; i < model.rowCount (); ++i) {
                const var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);
                const var providerId =  model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                            .toString ();
                if (type == Occ.UnifiedSearchResult.Type.FetchMoreTrigger
                    && providerId == providerIdFetchMoreTriggered) {
                    isFetchMoreTriggerFound = true;
                    break;
                }
            }

            QVERIFY (!isFetchMoreTriggerFound);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_search_term_result_tickled () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        // test that search term gets set, search gets started and enough results get returned
        model.setSearchTerm (model.searchTerm () + QStringLiteral ("discuss"));

        QSignalSpy searchInProgressChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has started
        QCOMPARE (searchInProgressChanged.count (), 1);
        QVERIFY (model.isSearchInProgress ());

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has on_finished and some results has been received
        QVERIFY (!model.isSearchInProgress ());

        QVERIFY (model.rowCount () != 0);

        QDesktopServices.setUrlHandler ("http", fakeDesktopServicesUrlHandler.data (), "resultClicked");
        QDesktopServices.setUrlHandler ("https", fakeDesktopServicesUrlHandler.data (), "resultClicked");

        QSignalSpy resultClicked (fakeDesktopServicesUrlHandler.data (), &FakeDesktopServicesUrlHandler.resultClicked);

        //  test click on a result item
        string urlForClickedResult;

        for (int i = 0; i < model.rowCount (); ++i) {
            const var type = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.TypeRole);

            if (type == Occ.UnifiedSearchResult.Type.Default) {
                const var providerId =
                    model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ProviderIdRole)
                        .toString ();
                urlForClickedResult = model.data (model.index (i), Occ.UnifiedSearchResultsListModel.DataRole.ResourceUrlRole).toString ();

                if (!providerId.isEmpty () && !urlForClickedResult.isEmpty ()) {
                    model.resultClicked (providerId, GLib.Uri (urlForClickedResult));
                    break;
                }
            }
        }

        QCOMPARE (resultClicked.count (), 1);

        const var arguments = resultClicked.takeFirst ();

        const var urlOpenTriggeredViaDesktopServices = arguments.at (0).toString ();

        QCOMPARE (urlOpenTriggeredViaDesktopServices, urlForClickedResult);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_search_term_results_error () {
        // make sure the model is empty
        model.setSearchTerm (QStringLiteral (""));
        QVERIFY (model.rowCount () == 0);

        QSignalSpy errorStringChanged (model.data (), &Occ.UnifiedSearchResultsListModel.errorStringChanged);
        QSignalSpy searchInProgressChanged (
            model.data (), &Occ.UnifiedSearchResultsListModel.isSearchInProgressChanged);

        model.setSearchTerm (model.searchTerm () + QStringLiteral ("[HTTP500]"));

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has started
        QVERIFY (model.isSearchInProgress ());

        QVERIFY (searchInProgressChanged.wait ());

        // make sure search has on_finished
        QVERIFY (!model.isSearchInProgress ());

        // make sure the model is empty and an error string has been set
        QVERIFY (model.rowCount () == 0);

        QVERIFY (errorStringChanged.count () > 0);

        QVERIFY (!model.errorString ().isEmpty ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_cleanup_test_case () {
        FakeSearchResultsStorage.destroy ();
    }
}

QTEST_MAIN (TestUnifiedSearchListmodel)
