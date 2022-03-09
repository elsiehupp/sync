/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

/***********************************************************
@brief The FakeSearchResultsStorage
emulates the real server storage that contains all the results that UnifiedSearchListmodel will search for
***********************************************************/
class FakeSearchResultsStorage {

    /***********************************************************
    ***********************************************************/
    private static FakeSearchResultsStorage instance;

    /***********************************************************
    ***********************************************************/
    private const int page_size = 5;

    /***********************************************************
    ***********************************************************/
    private GLib.HashMap<string, Provider> search_results_data;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray providers_response = fake_404_response;

    /***********************************************************
    ***********************************************************/
    private QVariantMap meta_success;
    
    class Provider {

        public class SearchResult {

            public string thumbnail_url;
            public string title;
            public string subline;
            public string resource_url;
            public string icon;
            public bool rounded;
        }

        string identifier;
        string name;
        int32 order = std.numeric_limits<int32>.max ();
        int32 cursor = 0;
        bool  is_paginated = false;
        GLib.Vector<SearchResult> results;
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
        if (!this.search_results_data.is_empty ()) {
            return;
        }

        this.meta_success = {
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

        init_providers_response ();

        init_search_results_data ();
    }

    /***********************************************************
    Initialize the JSON response containing the fake list of
    providers and their properties.
    ***********************************************************/
    public void init_providers_response () {

        GLib.List<GLib.Variant> providers_list;

        foreach (var fake_provider_init_info in fake_providers_init_info) {
            providers_list.push_back (new QVariantMap ({
                {
                    "identifier", fake_provider_init_info.id
                },
                {
                    "name", fake_provider_init_info.name
                },
                {
                    "order", fake_provider_init_info.order
                },
            }));
        }

        const QVariantMap ocs_map = {
            {
                "meta", this.meta_success
            },
            {
                "data", providers_list
            }
        }

        this.providers_response = QJsonDocument.from_variant (
            new QVariantMap ({
                {
                    "ocs", ocs_map
                }
            }).to_json (QJsonDocument.Compact)
        );
    }

    // on_signal_init the map of fake search results for each provider
    public void init_search_results_data () {
        foreach (var fake_provider in fake_providers_init_info) {
            var provider_data = this.search_results_data[fake_provider.id];
            provider_data.id = fake_provider.id;
            provider_data.name = fake_provider.name;
            provider_data.order = fake_provider.order;
            if (fake_provider.number_of_items_to_insert > page_size) {
                provider_data.is_paginated = true;
            }
            for (uint32 i = 0; i < fake_provider.number_of_items_to_insert; ++i) {
                provider_data.results.push_back (
                    {
                        "http://example.de/avatar/john/64",
                        "John Doe in " + fake_provider.name,
                        "We a discussion about " + fake_provider.name + " already. But, let's have a follow up tomorrow afternoon.",
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
    public const GLib.List<GLib.Variant> results_for_provider (string provider_id, int cursor) {
        GLib.List<GLib.Variant> list;

        var results = results_for_provider_as_vector (provider_id, cursor);

        if (results.is_empty ()) {
            return list;
        }

        foreach (var result in results) {
            list.push_back (new QVariantMap (
                {
                    "thumbnail_url", result.thumbnail_url
                },
                {
                    "title", result.title
                },
                {
                    "subline", result.subline
                },
                {
                    "resource_url", result.resource_url
                },
                {
                    "icon", result.icon
                },
                {
                    "rounded", result.rounded
                }
            ));
        }

        return list;
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.Vector<Provider.SearchResult> results_for_provider_as_vector (string provider_id, int cursor) {
        GLib.Vector<Provider.SearchResult> results;

        var provider = this.search_results_data.value (provider_id, Provider ());

        if (provider.id.is_empty () || cursor > provider.results.size ()) {
            return results;
        }

        const int n = cursor + page_size > provider.results.size ()
            ? 0
            : cursor + page_size;

        for (int i = cursor; i < n; ++i) {
            results.push_back (provider.results[i]);
        }

        return results;
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray query_provider (string provider_id, string search_term, int cursor) {
        if (!this.search_results_data.contains (provider_id)) {
            return fake_404_response;
        }

        if (search_term == "[HTTP500]") {
            return fake500Response;
        }

        if (search_term == "[empty]") {
            QVariantMap data_map = {
                {
                    "name", this.search_results_data[provider_id].name
                },
                {
                    "is_paginated", false
                },
                {
                    "cursor", 0
                },
                {
                    "entries", new QVariantList ()
                }
            };

            QVariantMap ocs_map = {
                {
                    "meta", this.meta_success
                },
                {
                    "data", data_map
                }
            };

            return QJsonDocument.from_variant (
                new QVariantMap (
                    {
                        "ocs", ocs_map
                    }
                )
            ).to_json (QJsonDocument.Compact);
        }

        var provider = this.search_results_data.value (provider_id, Provider ());

        var next_cursor = cursor + page_size;

        const QVariantMap data_map = {
            {
                "name", this.search_results_data[provider_id].name
            },
            {
                "is_paginated", this.search_results_data[provider_id].is_paginated
            },
            {
                "cursor", next_cursor
            },
            {
                "entries", results_for_provider (provider_id, cursor)
            }
        };

        QVariantMap ocs_map = {
            {
                "meta", this.meta_success
            },
            {
                "data", data_map
            }
        };

        return new QJsonDocument.from_variant (
            new QVariantMap (
                {
                    "ocs"), ocs_map
                }
            )
        ).to_json (QJsonDocument.Compact);
    }


    /***********************************************************
    ***********************************************************/
    public const GLib.ByteArray fake_providers_response_json () {
        return this.providers_response;
    }

}
}
