namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestUnifiedSearchListmodel

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class AbstractTestUnifiedSearchListmodel : GLib.Object {

    /***********************************************************
    ***********************************************************/
    protected const int SEARCH_RESULTS_REPLY_DELAY = 100;

    /***********************************************************
    ***********************************************************/
    protected FakeQNAM fake_access_manager;
    protected LibSync.Account account;
    protected AccountState account_state;
    protected UnifiedSearchResultsListModel model;
    protected GLib.AbstractItemModelTester model_tester;

    /***********************************************************
    ***********************************************************/
    protected FakeDesktopServicesUrlHandler fake_desktop_services_url_handler;

    /***********************************************************
    ***********************************************************/
    //  public AbstractTestUnifiedSearchListmodel ();

    /***********************************************************
    ***********************************************************/
    protected void on_signal_init_test_case () {
        fake_access_manager.reset (new FakeQNAM ({}));
        account = LibSync.Account.create ();
        account.set_credentials (new FakeCredentials (fake_access_manager));
        account.set_url (GLib.Uri ("http://example.de"));

        account_state.reset (new AccountState (account));

        fake_access_manager.set_override (
            this.init_test_case_override_delegate
        );

        model.reset (new UnifiedSearchResultsListModel (account_state));

        model_tester.reset (new GLib.AbstractItemModelTester (model));

        fake_desktop_services_url_handler.reset (new FakeDesktopServicesUrlHandler ());
    }


    /***********************************************************
    ***********************************************************/
    protected GLib.InputStream init_test_case_override_delegate (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {

        GLib.InputStream reply = null;

        var url_query = GLib.UrlQuery (request.url);
        var format = url_query.query_item_value ("format");
        var cursor = url_query.query_item_value ("cursor").to_int ();
        var search_term = url_query.query_item_value ("term");
        var path = request.url.path;

        if (!request.url.to_string ().has_prefix (account_state.account.url.to_string ())) {
            reply = new FakeErrorReply (operation, request, this, 404, FAKE_404_RESPONSE);
        }
        if (format != "json") {
            reply = new FakeErrorReply (operation, request, this, 400, FAKE_400_RESPONSE);
        }

        // handle fetch of providers list
        if (path.has_prefix ("/ocs/v2.php/search/providers") && search_term == "") {
            reply = new FakePayloadReply (operation, request,
                FakeSearchResultsStorage.instance.fake_providers_response_json (), fake_access_manager);
        // handle search for provider
        } else if (path.has_prefix ("/ocs/v2.php/search/providers") && !search_term == "") {
            var path_split = path.mid ("/ocs/v2.php/search/providers".size ())
                                       .split ("/", GLib.SkipEmptyParts);

            if (!path_split == "" && path.contains (path_split.nth_data (0))) {
                reply = new FakePayloadReply (operation, request,
                    FakeSearchResultsStorage.instance.query_provider (path_split.nth_data (0), search_term, cursor),
                    SEARCH_RESULTS_REPLY_DELAY, fake_access_manager);
            }
        }

        if (reply == null) {
            return (GLib.InputStream)new FakeErrorReply (operation, request, this, 404, "{error : \"Not found!\"}");
        }

        return reply;
    }


    /***********************************************************
    ***********************************************************/
    protected void clean_up () {
        FakeSearchResultsStorage.destroy ();
    }

} // class AbstractTestUnifiedSearchListmodel

} // namespace Testing
} // namespace Occ
