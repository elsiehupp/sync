/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

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
        if (!this.searchResultsData.is_empty ()) {
            return;
        }

        this.metaSuccess = {
            {
                "status", "ok"
            },
            {
                "statuscode", 200
            },
            {
                "message", "OK"
            }
        };

        initProvidersResponse ();

        initSearchResultsData ();
    }

    // initialize the JSON response containing the fake list of providers and their properties
    public void initProvidersResponse () {
        GLib.List<GLib.Variant> providersList;

        foreach (var fakeProviderInitInfo in fakeProvidersInitInfo) {
            providersList.push_back (new QVariantMap ({
                {
                    "identifier", fakeProviderInitInfo.id
                },
                {
                    "name", fakeProviderInitInfo.name
                },
                {
                    "order", fakeProviderInitInfo.order
                },
            }));
        }

        const QVariantMap ocsMap = {
            {
                "meta", this.metaSuccess
            },
            {
                "data", providersList
            }
        }

        this.providersResponse =
            QJsonDocument.fromVariant (new QVariantMap ({
                {
                    "ocs", ocsMap
                }
            }).to_json (QJsonDocument.Compact);
    }

    // on_signal_init the map of fake search results for each provider
    public void initSearchResultsData () {
        foreach (var fakeProvider in fakeProvidersInitInfo) {
            var providerData = this.searchResultsData[fakeProvider.id];
            providerData.id = fakeProvider.id;
            providerData.name = fakeProvider.name;
            providerData.order = fakeProvider.order;
            if (fakeProvider.numItemsToInsert > pageSize) {
                providerData.isPaginated = true;
            }
            for (uint32 i = 0; i < fakeProvider.numItemsToInsert; ++i) {
                providerData.results.push_back (
                    {
                        "http://example.de/avatar/john/64",
                        "John Doe in " + fakeProvider.name,
                        "We a discussion about " + fakeProvider.name + " already. But, let's have a follow up tomorrow afternoon.",
                        "http://example.de/call/abcde12345#message_12345",
                        "icon-talk",
                        true
                    }
                );
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.List<GLib.Variant> resultsForProvider (string provider_id, int cursor) {
        GLib.List<GLib.Variant> list;

        var results = resultsForProviderAsVector (provider_id, cursor);

        if (results.is_empty ()) {
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
    public const GLib.Vector<Provider.SearchResult> resultsForProviderAsVector (string provider_id, int cursor) {
        GLib.Vector<Provider.SearchResult> results;

        var provider = this.searchResultsData.value (provider_id, Provider ());

        if (provider.id.is_empty () || cursor > provider.results.size ()) {
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
    public const GLib.ByteArray query_provider (string provider_id, string search_term, int cursor) {
        if (!this.searchResultsData.contains (provider_id)) {
            return fake404Response;
        }

        if (search_term == "[HTTP500]") {
            return fake500Response;
        }

        if (search_term == "[empty]") {
            QVariantMap dataMap = {
                {
                    "name", this.searchResultsData[provider_id].name
                },
                {
                    "isPaginated", false
                },
                {
                    "cursor", 0
                },
                {
                    "entries", new QVariantList ()
                }
            };

            QVariantMap ocsMap = {
                {
                    "meta", this.metaSuccess
                },
                {
                    "data", dataMap
                }
            };

            return QJsonDocument.fromVariant (
                new QVariantMap (
                    {
                        "ocs", ocsMap
                    }
                )
            ).to_json (QJsonDocument.Compact);
        }

        var provider = this.searchResultsData.value (provider_id, Provider ());

        var nextCursor = cursor + pageSize;

        const QVariantMap dataMap = {
            {
                "name", this.searchResultsData[provider_id].name
            },
            {
                "isPaginated", this.searchResultsData[provider_id].isPaginated
            },
            {
                "cursor", nextCursor
            },
            {
                "entries", resultsForProvider (provider_id, cursor)
            }
        };

        QVariantMap ocsMap = {
            {
                "meta", this.metaSuccess
            },
            {
                "data", dataMap
            }
        };

        return new QJsonDocument.fromVariant (
            new QVariantMap (
                {
                    "ocs"), ocsMap
                }
            )
        ).to_json (QJsonDocument.Compact);
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray fake_providers_response_json () { return this.providersResponse; }


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
