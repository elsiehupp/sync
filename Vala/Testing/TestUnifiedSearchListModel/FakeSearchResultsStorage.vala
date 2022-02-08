/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The FakeSearchResultsStorage
emulates the real server storage that contains all the results that UnifiedSearchListmodel will search for
***********************************************************/
class FakeSearchResultsStorage { {lass Provider {
        public class SearchResult {

            public string this.thumbnailUrl;
            public string this.title;
            public string this.subline;
            public string this.resourceUrl;
            public string this.icon;
            public bool this.rounded;
        }

        string this.identifier;
        string this.name;
        int32 this.order = std.numeric_limits<int32>.max ();
        int32 this.cursor = 0;
        bool this.isPaginated = false;
        GLib.Vector<SearchResult> this.results;
    }

    FakeSearchResultsStorage () = default;


    /***********************************************************
    ***********************************************************/
    public static FakeSearchResultsStorage instance () {
        if (!this.instance) {
            this.instance = new FakeSearchResultsStorage ();
            this.instance.on_signal_init ();
        }

        return this.instance;
    }

    /***********************************************************
    ***********************************************************/
    public static void destroy () {
        if (this.instance) {
            delete this.instance;
        }

        this.instance = null;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_init () {
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
            providersList.push_back (QVariantMap{ {QStringLiteral ("identifier"), fakeProviderInitInfo.id}, {QStringLiteral ("name"), fakeProviderInitInfo.name}, {QStringLiteral ("order"), fakeProviderInitInfo.order},
            });
        }

        const QVariantMap ocsMap = { {QStringLiteral ("meta"), this.metaSuccess}, {QStringLiteral ("data"), providersList}
        }

        this.providersResponse =
            QJsonDocument.fromVariant (QVariantMap{{QStringLiteral ("ocs"), ocsMap}}).toJson (QJsonDocument.Compact);
    }

    // on_signal_init the map of fake search results for each provider
    public void initSearchResultsData () {
        for (var fakeProvider : fakeProvidersInitInfo) {
            var providerData = this.searchResultsData[fakeProvider.id];
            providerData.id = fakeProvider.id;
            providerData.name = fakeProvider.name;
            providerData.order = fakeProvider.order;
            if (fakeProvider.numItemsToInsert > pageSize) {
                providerData.isPaginated = true;
            }
            for (uint32 i = 0; i < fakeProvider.numItemsToInsert; ++i) {
                providerData.results.push_back ( {"http://example.de/avatar/john/64", string (QStringLiteral ("John Doe in ") + fakeProvider.name),
                        string (QStringLiteral ("We a discussion about ") + fakeProvider.name
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
            list.push_back (QVariantMap{ {"thumbnailUrl", result.thumbnailUrl}, {"title", result.title}, {"subline", result.subline}, {"resourceUrl", result.resourceUrl}, {"icon", result.icon}, {"rounded", result.rounded}
            });
        }

        return list;
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.Vector<Provider.SearchResult> resultsForProviderAsVector (string providerId, int cursor) {
        GLib.Vector<Provider.SearchResult> results;

        const var provider = this.searchResultsData.value (providerId, Provider ());

        if (provider.id.isEmpty () || cursor > provider.results.size ()) {
            return results;
        }

        const int n = cursor + pageSize > provider.results.size ()
            ? 0
            : cursor + pageSize;

        for (int i = cursor; i < n; ++i) {
            results.push_back (provider.results[i]);
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
            const QVariantMap dataMap = {{QStringLiteral ("name"), this.searchResultsData[providerId].name}, {QStringLiteral ("isPaginated"), false}, {QStringLiteral ("cursor"), 0}, {QStringLiteral ("entries"), QVariantList{}}};

            const QVariantMap ocsMap = {{QStringLiteral ("meta"), this.metaSuccess}, {QStringLiteral ("data"), dataMap}};

            return QJsonDocument.fromVariant (QVariantMap{{QStringLiteral ("ocs"), ocsMap}})
                .toJson (QJsonDocument.Compact);
        }

        const var provider = this.searchResultsData.value (providerId, Provider ());

        const var nextCursor = cursor + pageSize;

        const QVariantMap dataMap = {{QStringLiteral ("name"), this.searchResultsData[providerId].name}, {QStringLiteral ("isPaginated"), this.searchResultsData[providerId].isPaginated}, {QStringLiteral ("cursor"), nextCursor}, {QStringLiteral ("entries"), resultsForProvider (providerId, cursor)}};

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
    private const int pageSize = 5;

    /***********************************************************
    ***********************************************************/
    private GLib.HashMap<string, Provider> this.searchResultsData;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray this.providersResponse = fake404Response;

    /***********************************************************
    ***********************************************************/
    private QVariantMap this.metaSuccess;
}

FakeSearchResultsStorage *FakeSearchResultsStorage.instance = null;
