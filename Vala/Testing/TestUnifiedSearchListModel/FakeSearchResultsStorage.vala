/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

/***********************************************************
@brief The FakeSearchResultsStorage
emulates the real server storage that contains all the
results that UnifiedSearchListmodel will search for
***********************************************************/
public class FakeSearchResultsStorage { //: GLib.Object {

    //  /***********************************************************
    //  ***********************************************************/
    //  private static FakeSearchResultsStorage instance;

    //  /***********************************************************
    //  ***********************************************************/
    //  private const int page_size = 5;

    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.HashTable<string, Provider> search_results_data;

    //  /***********************************************************
    //  ***********************************************************/
    //  private string providers_response = FAKE_404_RESPONSE;

    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.HashMap meta_success;

    //  public class Provider { //: GLib.Object {

    //      public class SearchResult { //: GLib.Object {

    //          public string thumbnail_url;
    //          public string title;
    //          public string subline;
    //          public string resource_url;
    //          public string icon;
    //          public bool rounded;
    //      }

    //      string identifier;
    //      string name;
    //      int32 order = std.numeric_limits<int32>.max ();
    //      int32 cursor = 0;
    //      bool  is_paginated = false;
    //      GLib.List<SearchResult> results;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public static FakeSearchResultsStorage instance {
    //      if (!this.instance) {
    //          this.instance = new FakeSearchResultsStorage ();
    //          this.instance.on_signal_init ();
    //      }

    //      return this.instance;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public static void destroy () {
    //      if (FakeSearchResultsStorage.instance != null) {
    //          //  delete FakeSearchResultsStorage.instance;
    //      }
    //      FakeSearchResultsStorages.instance = null;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void on_signal_init () {
    //      if (this.search_results_data != null) {
    //          return;
    //      }

    //      this.meta_success = {
    //          {
    //              "status", "ok"
    //          },
    //          {
    //              "statuscode", 200
    //          },
    //          {
    //              "message", "OK"
    //          }
    //      };

    //      init_providers_response ();

    //      init_search_results_data ();
    //  }


    //  /***********************************************************
    //  Initialize the JSON response containing the fake list of
    //  providers and their properties.
    //  ***********************************************************/
    //  public void init_providers_response () {

    //      GLib.List<GLib.Variant> providers_list;

    //      foreach (var fake_provider_init_info in fake_providers_init_info) {
    //          providers_list.push_back (new GLib.HashMap ({
    //              {
    //                  "identifier", fake_provider_init_info.id
    //              },
    //              {
    //                  "name", fake_provider_init_info.name
    //              },
    //              {
    //                  "order", fake_provider_init_info.order
    //              },
    //          }));
    //      }

    //      GLib.HashMap ocs_map = new GLib.HashMap (
    //          {
    //              "meta", this.meta_success
    //          },
    //          {
    //              "data", providers_list
    //          }
    //      );

    //      this.providers_response = GLib.JsonDocument.from_variant (
    //          new GLib.HashMap ({
    //              {
    //                  "ocs", ocs_map
    //              }
    //          }).to_json (GLib.JsonDocument.Compact)
    //      );
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  // on_signal_init the map of fake search results for each provider
    //  public void init_search_results_data () {
    //      foreach (var fake_provider in fake_providers_init_info) {
    //          var provider_data = this.search_results_data[fake_provider.id];
    //          provider_data.id = fake_provider.id;
    //          provider_data.name = fake_provider.name;
    //          provider_data.order = fake_provider.order;
    //          if (fake_provider.number_of_items_to_insert > page_size) {
    //              provider_data.is_paginated = true;
    //          }
    //          for (uint32 i = 0; i < fake_provider.number_of_items_to_insert; ++i) {
    //              provider_data.results.push_back (
    //                  {
    //                      "http://example.de/avatar/john/64",
    //                      "John Doe in " + fake_provider.name,
    //                      "We a discussion about " + fake_provider.name + " already. But, let's have a follow up tomorrow afternoon.",
    //                      "http://example.de/call/abcde12345#message_12345",
    //                      "icon-talk",
    //                      true
    //                  }
    //              );
    //          }
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.List<Variant> results_for_provider (string provider_id, int cursor) {
    //      GLib.List<GLib.Variant> list;

    //      var results = results_for_provider_as_vector (provider_id, cursor);

    //      if (results == "") {
    //          return list;
    //      }

    //      foreach (var result in results) {
    //          list.push_back (new GLib.HashMap (
    //              {
    //                  "thumbnail_url", result.thumbnail_url
    //              },
    //              {
    //                  "title", result.title
    //              },
    //              {
    //                  "subline", result.subline
    //              },
    //              {
    //                  "resource_url", result.resource_url
    //              },
    //              {
    //                  "icon", result.icon
    //              },
    //              {
    //                  "rounded", result.rounded
    //              }
    //          ));
    //      }

    //      return list;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.List<Provider.SearchResult> results_for_provider_as_vector (string provider_id, int cursor) {
    //      GLib.List<Provider.SearchResult> results;

    //      var provider = this.search_results_data.value (provider_id, Provider ());

    //      if (provider.id == "" || cursor > provider.results.size ()) {
    //          return results;
    //      }

    //      int n = cursor + page_size > provider.results.size ()
    //          ? 0
    //          : cursor + page_size;

    //      for (int i = cursor; i < n; ++i) {
    //          results.push_back (provider.results[i]);
    //      }

    //      return results;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public string query_provider (string provider_id, string search_term, int cursor) {
    //      if (!this.search_results_data.contains (provider_id)) {
    //          return FAKE_404_RESPONSE;
    //      }

    //      if (search_term == "[HTTP500]") {
    //          return FAKE_500_RESPONSE;
    //      }

    //      if (search_term == "[empty]") {
    //          GLib.HashMap data_map = {
    //              {
    //                  "name", this.search_results_data[provider_id].name
    //              },
    //              {
    //                  "is_paginated", false
    //              },
    //              {
    //                  "cursor", 0
    //              },
    //              {
    //                  "entries", new GLib.VariantList ()
    //              }
    //          };

    //          GLib.HashMap ocs_map = {
    //              {
    //                  "meta", this.meta_success
    //              },
    //              {
    //                  "data", data_map
    //              }
    //          };

    //          return GLib.JsonDocument.from_variant (
    //              new GLib.HashMap (
    //                  {
    //                      "ocs", ocs_map
    //                  }
    //              )
    //          ).to_json (GLib.JsonDocument.Compact);
    //      }

    //      var provider = this.search_results_data.value (provider_id, Provider ());

    //      var next_cursor = cursor + page_size;

    //      GLib.HashMap data_map = {
    //          {
    //              "name", this.search_results_data[provider_id].name
    //          },
    //          {
    //              "is_paginated", this.search_results_data[provider_id].is_paginated
    //          },
    //          {
    //              "cursor", next_cursor
    //          },
    //          {
    //              "entries", results_for_provider (provider_id, cursor)
    //          }
    //      };

    //      GLib.HashMap ocs_map = {
    //          {
    //              "meta", this.meta_success
    //          },
    //          {
    //              "data", data_map
    //          }
    //      };

    //      return new GLib.JsonDocument.from_variant (
    //          new GLib.HashMap (
    //              {
    //                  "ocs", ocs_map
    //              }
    //          )
    //      ).to_json (GLib.JsonDocument.Compact);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public string fake_providers_response_json () {
    //      return this.providers_response;
    //  }

}

} // namespace Testing
} // namespace Occ
