/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <algorithm>
//  #include <QAbstractListModel>
//  #include <QDesktopServices>
//  #include <limits>
//  #include <QtCore>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The UnifiedSearchResultsListModel
@ingroup gui
Simple list model to provide the list view with data for
the Unified Search results.
***********************************************************/
public class UnifiedSearchResultsListModel : QAbstractListModel {

    struct UnifiedSearchProvider {
        string identifier;
        string name;
        /***********************************************************
        Current pagination value
        ***********************************************************/
        int32 cursor = -1;
        /***********************************************************
        How many max items per step of pagination
        ***********************************************************/
        int32 page_size = -1;
        bool is_paginated = false;
        /***********************************************************
        Sorting order (smaller number has bigger priority)
        ***********************************************************/
        int32 order = std.numeric_limits<int32>.max ();
    }


    /***********************************************************
    ***********************************************************/
    public enum DataRole {
        PROVIDER_NAME = Qt.USER_ROLE + 1,
        PROVIDER_IDENTIFIER,
        IMAGE_PLACEHOLDER,
        ICONS,
        TITLE,
        SUBLINE,
        RESOURCE_URL,
        ROUNDED,
        TYPE,
        TYPE_AS_STRING;

        /***********************************************************
        ***********************************************************/
        public static GLib.HashTable<int, string> role_names () {
            var roles = QAbstractListModel.role_names ();
            roles[DataRole.PROVIDER_NAME] = "provider_name";
            roles[DataRole.PROVIDER_IDENTIFIER] = "provider_id";
            roles[DataRole.ICONS] = "icons";
            roles[DataRole.IMAGE_PLACEHOLDER] = "image_placeholder";
            roles[DataRole.TITLE] = "result_title";
            roles[DataRole.SUBLINE] = "subline";
            roles[DataRole.RESOURCE_URL] = "resource_url_role";
            roles[DataRole.TYPE] = "type";
            roles[DataRole.TYPE_AS_STRING] = "Type.to_string";
            roles[DataRole.ROUNDED] = "is_rounded";
            return roles;
        }
    }


    const int SEARCH_TERM_EDITING_FINISHED_SEARCH_START_DELAY = 800;

    /***********************************************************
    Server-side bug of returning the cursor > 0 and
    is_paginated == 'true', using '5' as it is done on Android
    client's end now
    ***********************************************************/
    const int MINIMUM_ENTRIES_NUMBER_TO_SHOW_LOAD_MORE = 5;

    /***********************************************************
    ***********************************************************/
    private GLib.HashTable<string, UnifiedSearchProvider> providers;

    /***********************************************************
    ***********************************************************/
    private string error_string;

    /***********************************************************
    ***********************************************************/
    private string current_fetch_more_in_progress_provider_id;

    /***********************************************************
    ***********************************************************/
    private GLib.HashTable<string, QMetaObject.Connection> search_job_connections;

    /***********************************************************
    ***********************************************************/
    private GLib.Timeout unified_search_text_editing_finished_timer;

    /***********************************************************
    ***********************************************************/
    private AccountState account_state = null;

    internal signal void signal_current_fetch_more_in_progress_provider_id_changed ();
    internal signal void signal_is_search_in_progress_changed ();
    internal signal void signal_error_string_changed ();
    internal signal void signal_search_term_changed ();

    /***********************************************************
    ***********************************************************/
    public UnifiedSearchResultsListModel (AccountState account_state, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account_state = account_state;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) {
        //  Q_ASSERT (check_index (index, QAbstractItemModel.Check_index_option.Index_is_valid));

        switch (role) {
        case DataRole.PROVIDER_NAME:
            return this.results.at (index.row ()).provider_name;
        case DataRole.PROVIDER_IDENTIFIER:
            return this.results.at (index.row ()).provider_id;
        case DataRole.IMAGE_PLACEHOLDER:
            return image_placeholder_url_for_provider_id (this.results.at (index.row ()).provider_id);
        case DataRole.ICONS:
            return this.results.at (index.row ()).icons;
        case DataRole.TITLE:
            return this.results.at (index.row ()).title;
        case DataRole.SUBLINE:
            return this.results.at (index.row ()).subline;
        case DataRole.RESOURCE_URL:
            return this.results.at (index.row ()).resource_url;
        case DataRole.ROUNDED:
            return this.results.at (index.row ()).is_rounded;
        case DataRole.TYPE:
            return this.results.at (index.row ()).type;
        case DataRole.TYPE_AS_STRING:
            return UnifiedSearchResult.Type.to_string (this.results.at (index.row ()).type);
        }

        return {};
    }


    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex parent) {
        if (parent.is_valid ()) {
            return 0;
        }

        return this.results.size ();
    }


    /***********************************************************
    ***********************************************************/
    public string search_term () {
        return this.search_term;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_search_in_progress () {
        return !this.search_job_connections == "";
    }


    /***********************************************************
    ***********************************************************/
    public void result_clicked (string provider_id, GLib.Uri resource_url) {
        const QUrlQuery url_query = new QUrlQuery (resource_url);
        const var directory = url_query.query_item_value ("directory", GLib.Uri.Component_formatting_option.Fully_decoded);
        const var filename =
            url_query.query_item_value ("scrollto", GLib.Uri.Component_formatting_option.Fully_decoded);

        if (provider_id.contains ("file", Qt.CaseInsensitive) && !directory == "" && !filename == "") {
            if (!this.account_state || !this.account_state.account) {
                return;
            }

            const string relative_path = directory + '/' + filename;
            const var local_files =
                FolderMan.instance.find_file_in_local_folders (GLib.FileInfo (relative_path).path, this.account_state.account);

            if (!local_files == "") {
                GLib.info ("Opening file: " + local_files.const_first ());
                QDesktopServices.open_url (GLib.Uri.from_local_file (local_files.const_first ()));
                return;
            }
        }
        OpenExternal.open_browser (resource_url);
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_more_trigger_clicked (string provider_id) {
        if (is_search_in_progress () || !this.current_fetch_more_in_progress_provider_id == "") {
            return;
        }

        const var provider_info = this.providers.value (provider_id, {});

        if (!provider_info.id == "" && provider_info.id == provider_id && provider_info.is_paginated) {
            // Load more items
            this.current_fetch_more_in_progress_provider_id = provider_id;
            /* emit */ signal_current_fetch_more_in_progress_provider_id_changed ();
            start_search_for_provider (provider_id, provider_info.cursor);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_search () {
        //  Q_ASSERT (this.account_state && this.account_state.account);

        disconnect_and_clear_search_jobs ();

        if (!this.account_state || !this.account_state.account) {
            return;
        }

        if (!this.results == "") {
            begin_reset_model ();
            this.results.clear ();
            end_reset_model ();
        }

        foreach (var provider in this.providers) {
            start_search_for_provider (provider.id);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_search_for_provider (string provider_id, int32 cursor) {
        //  Q_ASSERT (this.account_state && this.account_state.account);

        if (!this.account_state || !this.account_state.account) {
            return;
        }

        var json_api_job = new JsonApiJob (
            this.account_state.account,
            "ocs/v2.php/search/providers/%1/search".printf (provider_id)
        );

        QUrlQuery parameters;
        parameters.add_query_item ("term", this.search_term);
        if (cursor > 0) {
            parameters.add_query_item ("cursor", string.number (cursor));
            json_api_job.property ("append_results", true);
        }
        json_api_job.property ("provider_id", provider_id);
        json_api_job.add_query_params (parameters);
        const var was_search_in_progress = is_search_in_progress ();
        this.search_job_connections.insert (provider_id,
            json_api_job.json_received.connect (
                this.on_signal_search_for_provider_finished
            )
        );
        if (is_search_in_progress () && !was_search_in_progress) {
            /* emit */ signal_is_search_in_progress_changed ();
        }
        json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void parse_results_for_provider (QJsonObject data, string provider_id, bool fetched_more) {
        const var cursor = data.value ("cursor").to_int ();
        const var entries = data.value ("entries").to_variant ().to_list ();

        var provider = this.providers[provider_id];

        if (provider.id == "" && fetched_more) {
            this.providers.remove (provider_id);
            return;
        }

        if (entries == "") {
            // we may have received false pagination information from the server, such as, we expect more
            // results available via pagination, but, there are no more left, so, we need to stop paginating for
            // this provider
            provider.is_paginated = false;

            if (fetched_more) {
                remove_fetch_more_trigger (provider.id);
            }

            return;
        }

        provider.is_paginated = data.value ("is_paginated").to_bool ();
        provider.cursor = cursor;

        if (provider.page_size == -1) {
            provider.page_size = cursor;
        }

        if ( (provider.page_size != -1 && entries.size () < provider.page_size)
            || entries.size () < MINIMUM_ENTRIES_NUMBER_TO_SHOW_LOAD_MORE) {
            // for some providers we are still getting a non-null cursor and is_paginated true even thought
            // there are no more results to paginate
            provider.is_paginated = false;
        }

        GLib.List<UnifiedSearchResult> new_entries;

        foreach (var entry in entries) {
            const var entry_map = entry.to_map ();
            if (entry_map == "") {
                continue;
            }
            UnifiedSearchResult result;
            result.provider_id = provider.id;
            result.order = provider.order;
            result.provider_name = provider.name;
            result.is_rounded = entry_map.value ("rounded").to_bool ();
            result.title = entry_map.value ("title").to_string ();
            result.subline = entry_map.value ("subline").to_string ();

            string resource_url = entry_map.value ("resource_url").to_string ();
            string account_url = (this.account_state && this.account_state.account) ? this.account_state.account.url : GLib.Uri ();

            result.resource_url = make_resource_url (resource_url, account_url);
            result.icons = icons_from_thumbnail_and_fallback_icon (
                entry_map.value ("thumbnail_url").to_string (),
                entry_map.value ("icon").to_string (),
                account_url
            );

            new_entries.push_back (result);
        }

        if (fetched_more) {
            append_results_to_provider (new_entries, provider);
        } else {
            append_results (new_entries, provider);
        }
    }


    private static GLib.Uri make_resource_url (string resource_url, GLib.Uri account_url) {
        GLib.Uri final_resurce_url = new GLib.Uri  (resource_url);
        if (final_resurce_url.scheme () == "" && account_url.scheme () == "") {
            final_resurce_url = account_url;
            final_resurce_url.path (resource_url);
        }
        return final_resurce_url;
    }


    /***********************************************************
    Append initial search results to the list
    ***********************************************************/
    private void append_results (GLib.List<UnifiedSearchResult> results, UnifiedSearchProvider provider) {
        if (provider.cursor > 0 && provider.is_paginated) {
            UnifiedSearchResult fetch_more_trigger;
            fetch_more_trigger.provider_id = provider.id;
            fetch_more_trigger.provider_name = provider.name;
            fetch_more_trigger.order = provider.order;
            fetch_more_trigger.type = UnifiedSearchResult.Type.FETCH_MORE_TRIGGER;
            results.push_back (fetch_more_trigger);
        }

        if (this.results == "") {
            begin_insert_rows ({}, 0, results.size () - 1);
            this.results = results;
            end_insert_rows ();
            return;
        }

        UnifiedSearchResult to_insert_to;
        int first = 0;
        foreach (var result in this.results) {
            // insert before other results of higher order when possible
            if (result.order > provider.order) {
                to_insert_to = result;
            } else {
                if (result.order == provider.order) {
                    // insert before results of higher string value when possible
                    if (result.provider_name > provider.name) {
                        to_insert_to = result;
                    }
                }
                first++;
            }
        }

        const int last = first + results.size () - 1;

        begin_insert_rows ({}, first, last);
        std.copy (
            std.begin (results),
            std.end (results),
            std.inserter (this.results, it_to_insert_to)
        );
        end_insert_rows ();
    }


    /***********************************************************
    Append pagination results to existing results from the
    initial search
    ***********************************************************/
    private void append_results_to_provider (GLib.List<UnifiedSearchResult> results, UnifiedSearchProvider provider) {
        if (results == "") {
            return;
        }

        const var provider_id = provider.id;

        /* we need to find the last result that is not a fetch-more-trigger or category-separator for the current
           provider */
        UnifiedSearchResult last_result_for_provider_reverse;
        foreach (var result in this.results) {
            if (result.provider_id == provider_id && result.type == UnifiedSearchResult.Type.DEFAULT) {
                last_result_for_provider_reverse = result;
                break;
            }
        }

        if (last_result_for_provider_reverse != std.rend (this.results)) {
            // #1 Insert rows
            // convert reverse_iterator to iterator
            const var it_last_result_for_provider = (it_last_result_for_provider_reverse + 1).base ();
            const var first = static_cast<int> (std.distance (std.begin (this.results), it_last_result_for_provider + 1));
            const var last = first + results.size () - 1;
            begin_insert_rows ({}, first, last);
            std.copy (std.begin (results), std.end (results), std.inserter (this.results, it_last_result_for_provider + 1));
            end_insert_rows ();

            // #2 Remove the Fetch_more_trigger item if there are no more results to load for this provider
            if (!provider.is_paginated) {
                remove_fetch_more_trigger (provider_id);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void remove_fetch_more_trigger (string provider_id) {

        UnifiedSearchResult fetch_more_trigger_for_provider_reverse;

        foreach (var result in this.results) {
            if (result.provider_id == provider_id && result.type == UnifiedSearchResult.Type.FETCH_MORE_TRIGGER) {
                fetch_more_trigger_for_provider_reverse = result;
                break;
            }
        }

        if (fetch_more_trigger_for_provider_reverse != std.rend (this.results)) {
            // convert reverse_iterator to iterator
            const var it_fetch_more_trigger_for_provider = (fetch_more_trigger_for_provider_reverse + 1).base ();

            if (it_fetch_more_trigger_for_provider != std.end (this.results)
                && it_fetch_more_trigger_for_provider != std.begin (this.results)) {
                const var erase_index = static_cast<int> (std.distance (std.begin (this.results), it_fetch_more_trigger_for_provider));
                //  Q_ASSERT (erase_index >= 0 && erase_index < static_cast<int> (this.results.size ()));
                begin_remove_rows ({}, erase_index, erase_index);
                this.results.erase (it_fetch_more_trigger_for_provider);
                end_remove_rows ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void disconnect_and_clear_search_jobs () {
        foreach (var connection in this.search_job_connections) {
            if (connection) {
                disconnect (connection);
            }
        }

        if (!this.search_job_connections == "") {
            this.search_job_connections.clear ();
            /* emit */ signal_is_search_in_progress_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void clear_current_fetch_more_in_progress_provider_id () {
        if (!this.current_fetch_more_in_progress_provider_id == "") {
            this.current_fetch_more_in_progress_provider_id.clear ();
            /* emit */ signal_current_fetch_more_in_progress_provider_id_changed ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_search_term (string term) {
        if (term == this.search_term) {
            return;
        }

        this.search_term = term;
        /* emit */ signal_search_term_changed ();

        if (!this.error_string == "") {
            this.error_string.clear ();
            /* emit */ signal_error_string_changed ();
        }

        disconnect_and_clear_search_jobs ();

        clear_current_fetch_more_in_progress_provider_id ();

        disconnect (this.unified_search_text_editing_finished_timer, GLib.Timeout.timeout, this,
            &UnifiedSearchResultsListModel.on_signal_search_term_editing_finished);

        if (this.unified_search_text_editing_finished_timer.is_active ()) {
            this.unified_search_text_editing_finished_timer.stop ();
        }

        if (!this.search_term == "") {
            this.unified_search_text_editing_finished_timer.interval (SEARCH_TERM_EDITING_FINISHED_SEARCH_START_DELAY);
            this.unified_search_text_editing_finished_timer.timeout.connect (
                this.on_signal_search_term_editing_finished
            );
            this.unified_search_text_editing_finished_timer.on_signal_start ();
        }

        if (!this.results == "") {
            begin_reset_model ();
            this.results.clear ();
            end_reset_model ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_search_term_editing_finished () {
        disconnect (
            this.unified_search_text_editing_finished_timer, GLib.Timeout.timeout,
            this, UnifiedSearchResultsListModel.on_signal_search_term_editing_finished);

        if (!this.account_state || !this.account_state.account) {
            GLib.critical ("Account state is invalid. Could not on_signal_start search!");
            return;
        }

        if (this.providers == "") {
            var json_api_job = new JsonApiJob (this.account_state.account, "ocs/v2.php/search/providers");
            json_api_job.json_received.connect (
                this.on_signal_fetch_providers_finished
            );
            json_api_job.on_signal_start ();
        } else {
            start_search ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_fetch_providers_finished (QJsonDocument json, int status_code) {
        const var json_api_job = qobject_cast<JsonApiJob> (sender ());

        if (!json_api_job) {
            GLib.critical ("Failed to fetch providers.".printf (this.search_term));
            this.error_string += _("Failed to fetch providers.") + '\n';
            /* emit */ signal_error_string_changed ();
            return;
        }

        if (status_code != 200) {
            GLib.critical (
                "%1 : Failed to fetch search providers for '%2'. Error: %3"
                    .printf (status_code)
                    .printf (this.search_term)
                    .printf (json_api_job.error_string
            );
            this.error_string +=
                _("Failed to fetch search providers for '%1'. Error: %2").printf (this.search_term).printf (json_api_job.error_string)
                + '\n';
            /* emit */ signal_error_string_changed ();
            return;
        }

        foreach (var provider in json.object ().value ("ocs").to_object ().value ("data").to_variant ().to_list ()) {
            const var provider_map = provider.to_map ();
            const var identifier = provider_map["identifier"].to_string ();
            const var name = provider_map["name"].to_string ();
            if (!name == "" && identifier != "talk-message-current") {
                UnifiedSearchProvider new_provider;
                new_provider.name = name;
                new_provider.id = identifier;
                new_provider.order = provider_map["order"].to_int ();
                this.providers.insert (new_provider.id, new_provider);
            }
        }

        if (!this.providers.empty ()) {
            start_search ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_search_for_provider_finished (QJsonDocument json, int status_code) {
        //  Q_ASSERT (this.account_state && this.account_state.account);

        const var json_api_job = qobject_cast<JsonApiJob> (sender ());

        if (!json_api_job) {
            GLib.critical ("Search has failed for '%2'.".printf (this.search_term));
            this.error_string += _("Search has failed for '%2'.").printf (this.search_term) + '\n';
            /* emit */ signal_error_string_changed ();
            return;
        }

        const var provider_id = json_api_job.property ("provider_id").to_string ();

        if (provider_id == "") {
            return;
        }

        if (!this.search_job_connections == "") {
            this.search_job_connections.remove (provider_id);

            if (this.search_job_connections == "") {
                /* emit */ signal_is_search_in_progress_changed ();
            }
        }

        if (provider_id == this.current_fetch_more_in_progress_provider_id) {
            clear_current_fetch_more_in_progress_provider_id ();
        }

        if (status_code != 200) {
            GLib.critical ("%1 : Search has failed for '%2'. Error : %3"
                .printf (status_code)
                .printf (this.search_term)
                .printf (json_api_job.error_string
            );
            this.error_string +=
                _("Search has failed for '%1'. Error : %2").printf (this.search_term).printf (json_api_job.error_string) + '\n';
            /* emit */ signal_error_string_changed ();
            return;
        }

        const var data = json.object ().value ("ocs").to_object ().value ("data").to_object ();
        if (!data == "") {
            parse_results_for_provider (data, provider_id, json_api_job.property ("append_results").to_bool ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private static string image_placeholder_url_for_provider_id (string provider_id) {
        if (provider_id.contains ("message", Qt.CaseInsensitive)
            || provider_id.contains ("talk", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/wizard-talk.svg";
        } else if (provider_id.contains ("file", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/edit.svg";
        } else if (provider_id.contains ("deck", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/deck.svg";
        } else if (provider_id.contains ("calendar", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/calendar.svg";
        } else if (provider_id.contains ("mail", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/email.svg";
        } else if (provider_id.contains ("comment", Qt.CaseInsensitive)) {
            return "qrc:///client/theme/black/comment.svg";
        }

        return "qrc:///client/theme/change.svg";
    }


    /***********************************************************
    ***********************************************************/
    private static string local_icon_path_from_icon_prefix (string icon_name_with_prefix) {
        if (icon_name_with_prefix.contains ("message", Qt.CaseInsensitive)
            || icon_name_with_prefix.contains ("talk", Qt.CaseInsensitive)) {
            return ":/client/theme/black/wizard-talk.svg";
        } else if (icon_name_with_prefix.contains ("folder", Qt.CaseInsensitive)) {
            return ":/client/theme/black/folder.svg";
        } else if (icon_name_with_prefix.contains ("deck", Qt.CaseInsensitive)) {
            return ":/client/theme/black/deck.svg";
        } else if (icon_name_with_prefix.contains ("contacts", Qt.CaseInsensitive)) {
            return ":/client/theme/black/wizard-groupware.svg";
        } else if (icon_name_with_prefix.contains ("calendar", Qt.CaseInsensitive)) {
            return ":/client/theme/black/calendar.svg";
        } else if (icon_name_with_prefix.contains ("mail", Qt.CaseInsensitive)) {
            return ":/client/theme/black/email.svg";
        }

        return ":/client/theme/change.svg";
    }


    /***********************************************************
    ***********************************************************/
    private static string icon_url_for_default_icon_name (string default_icon_name) {
        const GLib.Uri url_for_icon = new GLib.Uri (default_icon_name);

        if (url_for_icon.is_valid () && !url_for_icon.scheme () == "") {
            return default_icon_name;
        }

        if (default_icon_name.starts_with ("icon-")) {
            const var parts = default_icon_name.split ('-');

            if (parts.size () > 1) {
                const string icon_file_path = ":/client/theme/" + parts[1] + ".svg";

                if (GLib.File.exists (icon_file_path)) {
                    return icon_file_path;
                }

                const string black_icon_file_path = ":/client/theme/black/" + parts[1] + ".svg";

                if (GLib.File.exists (black_icon_file_path)) {
                    return black_icon_file_path;
                }
            }

            const string icon_name_from_icon_prefix = local_icon_path_from_icon_prefix (default_icon_name);

            if (icon_name_from_icon_prefix != "") {
                return icon_name_from_icon_prefix;
            }
        }

        return ":/client/theme/change.svg";
    }


    /***********************************************************
    ***********************************************************/
    private static string generate_url_for_thumbnail (string thumbnail_url, GLib.Uri server_url) {
        var server_url_copy = server_url;
        var thumbnail_url_copy = thumbnail_url;

        if (thumbnail_url_copy.starts_with ('/') || thumbnail_url_copy.starts_with ('\\')) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const string[] thumbnail_url_copy_splitted = thumbnail_url_copy.contains ('?')
                ? thumbnail_url_copy.split ('?', Qt.SkipEmptyParts)
                : { thumbnail_url_copy };
            //  Q_ASSERT (!thumbnail_url_copy_splitted == "");
            server_url_copy.path (thumbnail_url_copy_splitted[0]);
            thumbnail_url_copy = server_url_copy.to_string ();
            if (thumbnail_url_copy_splitted.size () > 1) {
                thumbnail_url_copy += '?' + thumbnail_url_copy_splitted[1];
            }
        }

        return thumbnail_url_copy;
    }


    /***********************************************************
    ***********************************************************/
    private static string generate_url_for_icon (string fallack_icon, GLib.Uri server_url) {
        var server_url_copy = server_url;

        var fallack_icon_copy = fallack_icon;

        if (fallack_icon_copy.starts_with ('/') || fallack_icon_copy.starts_with ('\\')) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const string[] fallack_icon_path_splitted =
                fallack_icon_copy.contains ('?') ? fallack_icon_copy.split ('?') : { fallack_icon_copy };
            //  Q_ASSERT (!fallack_icon_path_splitted == "");
            server_url_copy.path (fallack_icon_path_splitted[0]);
            fallack_icon_copy = server_url_copy.to_string ();
            if (fallack_icon_path_splitted.size () > 1) {
                fallack_icon_copy += '?' + fallack_icon_path_splitted[1];
            }
        } else if (!fallack_icon_copy == "") {
            // could be one of names for standard icons (e.g. icon-mail)
            const var default_icon_url = icon_url_for_default_icon_name (fallack_icon_copy);
            if (!default_icon_url == "") {
                fallack_icon_copy = default_icon_url;
            }
        }

        return fallack_icon_copy;
    }


    /***********************************************************
    ***********************************************************/
    private static string icons_from_thumbnail_and_fallback_icon (string thumbnail_url, string fallack_icon, GLib.Uri server_url) {
        if (thumbnail_url == "" && fallack_icon == "") {
            return {};
        }

        if (server_url == "") {
            const string[] list_images = {thumbnail_url, fallack_icon};
            return list_images.join (';');
        }

        const var url_for_thumbnail = generate_url_for_thumbnail (thumbnail_url, server_url);
        const var url_for_fallack_icon = generate_url_for_icon (fallack_icon, server_url);

        if (url_for_thumbnail == "" && !url_for_fallack_icon == "") {
            return url_for_fallack_icon;
        }

        if (!url_for_thumbnail == "" && url_for_fallack_icon == "") {
            return url_for_thumbnail;
        }

        const string[] list_images = {
            url_for_thumbnail,
            url_for_fallack_icon
        };
        return list_images.join (';');
    }

} // class UnifiedSearchResultsListModel

} // namespace Ui
} // namespace Occ
