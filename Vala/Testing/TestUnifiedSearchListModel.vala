/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QAbstractItemModelTester>
// #include <QDesktopServices>
// #include <QSignalSpy>
// #include <QTest>

namespace {
/***********************************************************
@brief The FakeDesktopServicesUrlHandler
overrides QDesktopServices.openUrl
 **/
class FakeDesktopServicesUrlHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public FakeDesktopServicesUrlHandler (GLib.Object parent = new GLib.Object ())
        : GLib.Object (parent) {}

signals:
    void resultClicked (GLib.Uri url);
};

/***********************************************************
@brief The FakeProvider
is a simple structure that represents initial list of providers and their properties
 **/
class FakeProvider {

    /***********************************************************
    ***********************************************************/
    public string this.id;
    public string this.name;
    public int32 this.order = std.numeric_limits<int32>.max ();


    /***********************************************************
    ***********************************************************/
    public uint32 this.numItemsToInsert = 5; // how many fake resuls to insert
};

// this will be used when initializing fake search results data for each provider
static const GLib.Vector<FakeProvider> fakeProvidersInitInfo = { {QStringLiteral ("settings_apps"), QStringLiteral ("Apps"), -50, 10}, {QStringLiteral ("talk-message"), QStringLiteral ("Messages"), -2, 17}, {QStringLiteral ("files"), QStringLiteral ("Files"), 5, 3}, {QStringLiteral ("deck"), QStringLiteral ("Deck"), 10, 5}, {QStringLiteral ("comments"), QStringLiteral ("Comments"), 10, 2}, {QStringLiteral ("mail"), QStringLiteral ("Mails"), 10, 15}, {QStringLiteral ("calendar"), QStringLiteral ("Events"), 30, 11}
};

static GLib.ByteArray fake404Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":404,"message":"Invalid query, please check the syntax. API specifications are here : http:\/\/www.freedesktop.org\/wiki\/Specifications\/open-collaboration-services.\n"},"data":[]}}
)";

static GLib.ByteArray fake400Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":400,"message":"Parameter is incorrect.\n"},"data":[]}}
)";

static GLib.ByteArray fake500Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":500,"message":"Internal Server Error.\n"},"data":[]}}
)";

/***********************************************************
@brief The FakeSearchResultsStorage
emulates the real server storage that contains all the results that UnifiedSearchListmodel will search for
 **/
class FakeSearchResultsStorage { {lass Provider {
        public class SearchResult {

            public string this.thumbnailUrl;
            public string this.title;
            public string this.subline;
            public string this.resourceUrl;
            public string this.icon;
            public bool this.rounded;
        };

        string this.id;
        string this.name;
        int32 this.order = std.numeric_limits<int32>.max ();
        int32 this.cursor = 0;
        bool this.isPaginated = false;
        GLib.Vector<SearchResult> this.results;
    };

    FakeSearchResultsStorage () = default;


    /***********************************************************
    ***********************************************************/
    public static FakeSearchResultsStorage instance () {
        if (!this.instance) {
            this.instance = new FakeSearchResultsStorage ();
            this.instance.on_init ();
        }

        return this.instance;
    };

    /***********************************************************
    ***********************************************************/
    public static void destroy () {
        if (this.instance) {
            delete this.instance;
        }

        this.instance = nullptr;
    }


    /***********************************************************
    ***********************************************************/
    public void on_init () {
        if (!this.searchResultsData.isEmpty ()) {
            return;
        }

        this.metaSuccess = {{QStringLiteral ("status"), QStringLiteral ("ok")}, {QStringLiteral ("statuscode"), 200}, {QStringLiteral ("message"), QStringLiteral ("OK")}};

        initProvidersResponse ();

        initSearchResultsData ();
    }

    // initialize the JSON response containing the fake list of providers and their properties
    public void initProvidersResponse () {
        GLib.List<GLib.Variant> providersList;

        for (var fakeProviderInitInfo : fakeProvidersInitInfo) {
            providersList.push_back (QVariantMap{ {QStringLiteral ("id"), fakeProviderInitInfo._id}, {QStringLiteral ("name"), fakeProviderInitInfo._name}, {QStringLiteral ("order"), fakeProviderInitInfo._order},
            });
        }

        const QVariantMap ocsMap = { {QStringLiteral ("meta"), this.metaSuccess}, {QStringLiteral ("data"), providersList}
        };

        this.providersResponse =
            QJsonDocument.fromVariant (QVariantMap{{QStringLiteral ("ocs"), ocsMap}}).toJson (QJsonDocument.Compact);
    }

    // on_init the map of fake search results for each provider
    public void initSearchResultsData () {
        for (var fakeProvider : fakeProvidersInitInfo) {
            var providerData = this.searchResultsData[fakeProvider._id];
            providerData._id = fakeProvider._id;
            providerData._name = fakeProvider._name;
            providerData._order = fakeProvider._order;
            if (fakeProvider._numItemsToInsert > pageSize) {
                providerData._isPaginated = true;
            }
            for (uint32 i = 0; i < fakeProvider._numItemsToInsert; ++i) {
                providerData._results.push_back ( {"http://example.de/avatar/john/64", string (QStringLiteral ("John Doe in ") + fakeProvider._name),
                        string (QStringLiteral ("We a discussion about ") + fakeProvider._name
                            + QStringLiteral (" already. But, let's have a follow up tomorrow afternoon.")),
                        "http://example.de/call/abcde12345#message_12345", QStringLiteral ("icon-talk"), true});
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.List<GLib.Variant> resultsForProvider (string providerId, int cursor) {
        GLib.List<GLib.Variant> list;

        const var results = resultsForProviderAsVector (providerId, cursor);

        if (results.isEmpty ()) {
            return list;
        }

        for (var result : results) {
            list.push_back (QVariantMap{ {"thumbnailUrl", result._thumbnailUrl}, {"title", result._title}, {"subline", result._subline}, {"resourceUrl", result._resourceUrl}, {"icon", result._icon}, {"rounded", result._rounded}
            });
        }

        return list;
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.Vector<Provider.SearchResult> resultsForProviderAsVector (string providerId, int cursor) {
        GLib.Vector<Provider.SearchResult> results;

        const var provider = this.searchResultsData.value (providerId, Provider ());

        if (provider._id.isEmpty () || cursor > provider._results.size ()) {
            return results;
        }

        const int n = cursor + pageSize > provider._results.size ()
            ? 0
            : cursor + pageSize;

        for (int i = cursor; i < n; ++i) {
            results.push_back (provider._results[i]);
        }

        return results;
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray queryProvider (string providerId, string searchTerm, int cursor) {
        if (!this.searchResultsData.contains (providerId)) {
            return fake404Response;
        }

        if (searchTerm == QStringLiteral ("[HTTP500]")) {
            return fake500Response;
        }

        if (searchTerm == QStringLiteral ("[empty]")) {
            const QVariantMap dataMap = {{QStringLiteral ("name"), this.searchResultsData[providerId]._name}, {QStringLiteral ("isPaginated"), false}, {QStringLiteral ("cursor"), 0}, {QStringLiteral ("entries"), QVariantList{}}};

            const QVariantMap ocsMap = {{QStringLiteral ("meta"), this.metaSuccess}, {QStringLiteral ("data"), dataMap}};

            return QJsonDocument.fromVariant (QVariantMap{{QStringLiteral ("ocs"), ocsMap}})
                .toJson (QJsonDocument.Compact);
        }

        const var provider = this.searchResultsData.value (providerId, Provider ());

        const var nextCursor = cursor + pageSize;

        const QVariantMap dataMap = {{QStringLiteral ("name"), this.searchResultsData[providerId]._name}, {QStringLiteral ("isPaginated"), this.searchResultsData[providerId]._isPaginated}, {QStringLiteral ("cursor"), nextCursor}, {QStringLiteral ("entries"), resultsForProvider (providerId, cursor)}};

        const QVariantMap ocsMap = {{QStringLiteral ("meta"), this.metaSuccess}, {QStringLiteral ("data"), dataMap}};

        return QJsonDocument.fromVariant (QVariantMap{{QStringLiteral ("ocs"), ocsMap}}).toJson (QJsonDocument.Compact);
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray fakeProvidersResponseJson () { return this.providersResponse; }


    /***********************************************************
    ***********************************************************/
    private static FakeSearchResultsStorage this.instance;

    /***********************************************************
    ***********************************************************/
    private static const int pageSize = 5;

    /***********************************************************
    ***********************************************************/
    private QMap<string, Provider> this.searchResultsData;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.providersResponse = fake404Response;

    /***********************************************************
    ***********************************************************/
    private QVariantMap this.metaSuccess;
};

FakeSearchResultsStorage *FakeSearchResultsStorage._instance = nullptr;

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
    public static const int searchResultsReplyDelay = 100;

    /***********************************************************
    ***********************************************************/
    private void on_init_test_case () {
        fakeQnam.on_reset (new FakeQNAM ({}));
        account = Occ.Account.create ();
        account.setCredentials (new FakeCredentials{fakeQnam.data ()});
        account.setUrl (GLib.Uri ( ("http://example.de")));

        accountState.on_reset (new Occ.AccountState (account));

        fakeQnam.setOverride ([this] (QNetworkAccessManager.Operation op, QNetworkRequest req, QIODevice device) {
            Q_UNUSED (device);
            QNetworkReply reply = nullptr;

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
                return qobject_cast<QNetworkReply> (new FakeErrorReply (op, req, this, 404, QByteArrayLiteral ("{error : \"Not found!\"}")));
            }

            return reply;
        });

        model.on_reset (new Occ.UnifiedSearchResultsListModel (accountState.data ()));

        modelTester.on_reset (new QAbstractItemModelTester (model.data ()));

        fakeDesktopServicesUrlHandler.on_reset (new FakeDesktopServicesUrlHandler);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_set_search_term_start_stop_search () {
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
    private void on_test_set_search_term_results_found () {
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
    private void on_test_set_search_term_results_not_found () {
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
    private void on_test_set_search_term_results_error () {
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
};

QTEST_MAIN (TestUnifiedSearchListmodel)
