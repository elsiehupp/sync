/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <algorithm>

// #include <QAbstractListModel>
// #include <QDesktopServices>

// #pragma once

// #include <limits>

// #include <QtCore>

namespace Occ {

/***********************************************************
@brief The Unified_search_results_list_model
@ingroup gui
Simple list model to provide the list view with data for the Unified Search results.
***********************************************************/

class Unified_search_results_list_model : QAbstractListModel {

    Q_PROPERTY (bool is_search_in_progress READ is_search_in_progress NOTIFY is_search_in_progress_changed)
    Q_PROPERTY (string current_fetch_more_in_progress_provider_id READ current_fetch_more_in_progress_provider_id NOTIFY
            current_fetch_more_in_progress_provider_id_changed)
    Q_PROPERTY (string error_string READ error_string NOTIFY error_string_changed)
    Q_PROPERTY (string search_term READ search_term WRITE on_set_search_term NOTIFY search_term_changed)

    struct Unified_search_provider {
        string this.id;
        string this.name;
        int32 this.cursor = -1; // current pagination value
        int32 this.page_size = -1; // how many max items per step of pagination
        bool this.is_paginated = false;
        int32 this.order = std.numeric_limits<int32>.max (); // sorting order (smaller number has bigger priority)
    };


    /***********************************************************
    ***********************************************************/
    public enum Data_role {
        Provider_name_role = Qt.User_role + 1,
        Provider_id_role,
        Image_placeholder_role,
        Icons_role,
        Title_role,
        Subline_role,
        Resource_url_role,
        Rounded_role,
        Type_role,
        Type_as_string_role,
    };

    /***********************************************************
    ***********************************************************/
    public Unified_search_results_list_model (AccountState account_state, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) override;

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string search_term ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void fetch_more_trigger_clicked (string provider_id);

    public GLib.HashMap<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private void start_search ();

    /***********************************************************
    ***********************************************************/
    private 
    private void parse_results_for_provider (QJsonObject data, string provider_id, bool fetched_more = false);

    // append initial search results to the list
    private void append_results (GLib.Vector<Unified_search_result> results, Unified_search_provider provider);

    // append pagination results to existing results from the initial search
    private void append_results_to_provider (GLib.Vector<Unified_search_result> results, Unified_search_provider provider);

    /***********************************************************
    ***********************************************************/
    private void remove_fetch_more_trigger (string provider_id);

    /***********************************************************
    ***********************************************************/
    private void disconnect_and_clear_search_jobs ();

    /***********************************************************
    ***********************************************************/
    private void clear_current_fetch_more_in_progress_provider_id ();

signals:
    void current_fetch_more_in_progress_provider_id_changed ();
    void is_search_in_progress_changed ();
    void error_string_changed ();
    void search_term_changed ();


    /***********************************************************
    ***********************************************************/
    public void on_set_search_term (string term);


    /***********************************************************
    ***********************************************************/
    private void on_search_term_editing_finished ();
    private void on_fetch_providers_finished (QJsonDocument json, int status_code);
    private void on_search_for_provider_finished (QJsonDocument json, int status_code);


    /***********************************************************
    ***********************************************************/
    private QMap<string, Unified_search_provider> this.providers;

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private string this.error_string;

    /***********************************************************
    ***********************************************************/
    private string this.current_fetch_more_in_progress_provider_id;

    /***********************************************************
    ***********************************************************/
    private QMap<string, QMetaObject.Connection> this.search_job_co

    /***********************************************************
    ***********************************************************/
    private QTimer this.unified_search_text_editing_finished_timer;

    /***********************************************************
    ***********************************************************/
    private AccountState this.account_state = nullptr;
};
}








namespace {
    string image_placeholder_url_for_provider_id (string provider_id) {
        if (provider_id.contains (QStringLiteral ("message"), Qt.CaseInsensitive)
            || provider_id.contains (QStringLiteral ("talk"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/wizard-talk.svg");
        } else if (provider_id.contains (QStringLiteral ("file"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/edit.svg");
        } else if (provider_id.contains (QStringLiteral ("deck"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/deck.svg");
        } else if (provider_id.contains (QStringLiteral ("calendar"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/calendar.svg");
        } else if (provider_id.contains (QStringLiteral ("mail"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/email.svg");
        } else if (provider_id.contains (QStringLiteral ("comment"), Qt.CaseInsensitive)) {
            return QStringLiteral ("qrc:///client/theme/black/comment.svg");
        }

        return QStringLiteral ("qrc:///client/theme/change.svg");
    }

    string local_icon_path_from_icon_prefix (string icon_name_with_prefix) {
        if (icon_name_with_prefix.contains (QStringLiteral ("message"), Qt.CaseInsensitive)
            || icon_name_with_prefix.contains (QStringLiteral ("talk"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/wizard-talk.svg");
        } else if (icon_name_with_prefix.contains (QStringLiteral ("folder"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/folder.svg");
        } else if (icon_name_with_prefix.contains (QStringLiteral ("deck"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/deck.svg");
        } else if (icon_name_with_prefix.contains (QStringLiteral ("contacts"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/wizard-groupware.svg");
        } else if (icon_name_with_prefix.contains (QStringLiteral ("calendar"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/calendar.svg");
        } else if (icon_name_with_prefix.contains (QStringLiteral ("mail"), Qt.CaseInsensitive)) {
            return QStringLiteral (":/client/theme/black/email.svg");
        }

        return QStringLiteral (":/client/theme/change.svg");
    }

    string icon_url_for_default_icon_name (string default_icon_name) {
        const GLib.Uri url_for_icon{default_icon_name};

        if (url_for_icon.is_valid () && !url_for_icon.scheme ().is_empty ()) {
            return default_icon_name;
        }

        if (default_icon_name.starts_with (QStringLiteral ("icon-"))) {
            const var parts = default_icon_name.split ('-');

            if (parts.size () > 1) {
                const string icon_file_path = QStringLiteral (":/client/theme/") + parts[1] + QStringLiteral (".svg");

                if (GLib.File.exists (icon_file_path)) {
                    return icon_file_path;
                }

                const string black_icon_file_path = QStringLiteral (":/client/theme/black/") + parts[1] + QStringLiteral (".svg");

                if (GLib.File.exists (black_icon_file_path)) {
                    return black_icon_file_path;
                }
            }

            const var icon_name_from_icon_prefix = local_icon_path_from_icon_prefix (default_icon_name);

            if (!icon_name_from_icon_prefix.is_empty ()) {
                return icon_name_from_icon_prefix;
            }
        }

        return QStringLiteral (":/client/theme/change.svg");
    }

    string generate_url_for_thumbnail (string thumbnail_url, GLib.Uri server_url) {
        var server_url_copy = server_url;
        var thumbnail_url_copy = thumbnail_url;

        if (thumbnail_url_copy.starts_with ('/') || thumbnail_url_copy.starts_with ('\\')) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const string[] thumbnail_url_copy_splitted = thumbnail_url_copy.contains ('?')
                ? thumbnail_url_copy.split ('?', Qt.Skip_empty_parts)
                : string[]{thumbnail_url_copy};
            Q_ASSERT (!thumbnail_url_copy_splitted.is_empty ());
            server_url_copy.set_path (thumbnail_url_copy_splitted[0]);
            thumbnail_url_copy = server_url_copy.to_"";
            if (thumbnail_url_copy_splitted.size () > 1) {
                thumbnail_url_copy += '?' + thumbnail_url_copy_splitted[1];
            }
        }

        return thumbnail_url_copy;
    }

    string generate_url_for_icon (string fallack_icon, GLib.Uri server_url) {
        var server_url_copy = server_url;

        var fallack_icon_copy = fallack_icon;

        if (fallack_icon_copy.starts_with ('/') || fallack_icon_copy.starts_with ('\\')) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const string[] fallack_icon_path_splitted =
                fallack_icon_copy.contains ('?') ? fallack_icon_copy.split ('?') : string[]{fallack_icon_copy};
            Q_ASSERT (!fallack_icon_path_splitted.is_empty ());
            server_url_copy.set_path (fallack_icon_path_splitted[0]);
            fallack_icon_copy = server_url_copy.to_"";
            if (fallack_icon_path_splitted.size () > 1) {
                fallack_icon_copy += '?' + fallack_icon_path_splitted[1];
            }
        } else if (!fallack_icon_copy.is_empty ()) {
            // could be one of names for standard icons (e.g. icon-mail)
            const var default_icon_url = icon_url_for_default_icon_name (fallack_icon_copy);
            if (!default_icon_url.is_empty ()) {
                fallack_icon_copy = default_icon_url;
            }
        }

        return fallack_icon_copy;
    }

    string icons_from_thumbnail_and_fallback_icon (string thumbnail_url, string fallack_icon, GLib.Uri server_url) {
        if (thumbnail_url.is_empty () && fallack_icon.is_empty ()) {
            return {};
        }

        if (server_url.is_empty ()) {
            const string[] list_images = {thumbnail_url, fallack_icon};
            return list_images.join (';');
        }

        const var url_for_thumbnail = generate_url_for_thumbnail (thumbnail_url, server_url);
        const var url_for_fallack_icon = generate_url_for_icon (fallack_icon, server_url);

        if (url_for_thumbnail.is_empty () && !url_for_fallack_icon.is_empty ()) {
            return url_for_fallack_icon;
        }

        if (!url_for_thumbnail.is_empty () && url_for_fallack_icon.is_empty ()) {
            return url_for_thumbnail;
        }

        const string[] list_images{url_for_thumbnail, url_for_fallack_icon};
        return list_images.join (';');
    }

    constexpr int search_term_editing_finished_search_start_delay = 800;

    // server-side bug of returning the cursor > 0 and is_paginated == 'true', using '5' as it is done on Android client's end now
    constexpr int minimum_entres_number_to_show_load_more = 5;

    Unified_search_results_list_model.Unified_search_results_list_model (AccountState account_state, GLib.Object parent)
        : QAbstractListModel (parent)
        , this.account_state (account_state) {
    }

    GLib.Variant Unified_search_results_list_model.data (QModelIndex index, int role) {
        Q_ASSERT (check_index (index, QAbstractItemModel.Check_index_option.Index_is_valid));

        switch (role) {
        case Provider_name_role:
            return this.results.at (index.row ())._provider_name;
        case Provider_id_role:
            return this.results.at (index.row ())._provider_id;
        case Image_placeholder_role:
            return image_placeholder_url_for_provider_id (this.results.at (index.row ())._provider_id);
        case Icons_role:
            return this.results.at (index.row ())._icons;
        case Title_role:
            return this.results.at (index.row ())._title;
        case Subline_role:
            return this.results.at (index.row ())._subline;
        case Resource_url_role:
            return this.results.at (index.row ())._resource_url;
        case Rounded_role:
            return this.results.at (index.row ())._is_rounded;
        case Type_role:
            return this.results.at (index.row ())._type;
        case Type_as_string_role:
            return Unified_search_result.type_as_string (this.results.at (index.row ())._type);
        }

        return {};
    }

    int Unified_search_results_list_model.row_count (QModelIndex parent) {
        if (parent.is_valid ()) {
            return 0;
        }

        return this.results.size ();
    }

    GLib.HashMap<int, GLib.ByteArray> Unified_search_results_list_model.role_names () {
        var roles = QAbstractListModel.role_names ();
        roles[Provider_name_role] = "provider_name";
        roles[Provider_id_role] = "provider_id";
        roles[Icons_role] = "icons";
        roles[Image_placeholder_role] = "image_placeholder";
        roles[Title_role] = "result_title";
        roles[Subline_role] = "subline";
        roles[Resource_url_role] = "resource_url_role";
        roles[Type_role] = "type";
        roles[Type_as_string_role] = "type_as_string";
        roles[Rounded_role] = "is_rounded";
        return roles;
    }

    string Unified_search_results_list_model.search_term () {
        return this.search_term;
    }

    string Unified_search_results_list_model.error_string () {
        return this.error_string;
    }

    string Unified_search_results_list_model.current_fetch_more_in_progress_provider_id () {
        return this.current_fetch_more_in_progress_provider_id;
    }

    void Unified_search_results_list_model.on_set_search_term (string term) {
        if (term == this.search_term) {
            return;
        }

        this.search_term = term;
        /* emit */ search_term_changed ();

        if (!this.error_string.is_empty ()) {
            this.error_string.clear ();
            /* emit */ error_string_changed ();
        }

        disconnect_and_clear_search_jobs ();

        clear_current_fetch_more_in_progress_provider_id ();

        disconnect (&this.unified_search_text_editing_finished_timer, &QTimer.timeout, this,
            &Unified_search_results_list_model.on_search_term_editing_finished);

        if (this.unified_search_text_editing_finished_timer.is_active ()) {
            this.unified_search_text_editing_finished_timer.stop ();
        }

        if (!this.search_term.is_empty ()) {
            this.unified_search_text_editing_finished_timer.set_interval (search_term_editing_finished_search_start_delay);
            connect (&this.unified_search_text_editing_finished_timer, &QTimer.timeout, this,
                &Unified_search_results_list_model.on_search_term_editing_finished);
            this.unified_search_text_editing_finished_timer.on_start ();
        }

        if (!this.results.is_empty ()) {
            begin_reset_model ();
            this.results.clear ();
            end_reset_model ();
        }
    }

    bool Unified_search_results_list_model.is_search_in_progress () {
        return !this.search_job_connections.is_empty ();
    }

    void Unified_search_results_list_model.result_clicked (string provider_id, GLib.Uri resource_url) {
        const QUrlQuery url_query{resource_url};
        const var dir = url_query.query_item_value (QStringLiteral ("dir"), GLib.Uri.Component_formatting_option.Fully_decoded);
        const var filename =
            url_query.query_item_value (QStringLiteral ("scrollto"), GLib.Uri.Component_formatting_option.Fully_decoded);

        if (provider_id.contains (QStringLiteral ("file"), Qt.CaseInsensitive) && !dir.is_empty () && !filename.is_empty ()) {
            if (!this.account_state || !this.account_state.account ()) {
                return;
            }

            const string relative_path = dir + '/' + filename;
            const var local_files =
                FolderMan.instance ().find_file_in_local_folders (QFileInfo (relative_path).path (), this.account_state.account ());

            if (!local_files.is_empty ()) {
                q_c_info (lc_unified_search) << "Opening file:" << local_files.const_first ();
                QDesktopServices.open_url (GLib.Uri.from_local_file (local_files.const_first ()));
                return;
            }
        }
        Utility.open_browser (resource_url);
    }

    void Unified_search_results_list_model.fetch_more_trigger_clicked (string provider_id) {
        if (is_search_in_progress () || !this.current_fetch_more_in_progress_provider_id.is_empty ()) {
            return;
        }

        const var provider_info = this.providers.value (provider_id, {});

        if (!provider_info._id.is_empty () && provider_info._id == provider_id && provider_info._is_paginated) {
            // Load more items
            this.current_fetch_more_in_progress_provider_id = provider_id;
            /* emit */ current_fetch_more_in_progress_provider_id_changed ();
            start_search_for_provider (provider_id, provider_info._cursor);
        }
    }

    void Unified_search_results_list_model.on_search_term_editing_finished () {
        disconnect (&this.unified_search_text_editing_finished_timer, &QTimer.timeout, this,
            &Unified_search_results_list_model.on_search_term_editing_finished);

        if (!this.account_state || !this.account_state.account ()) {
            q_c_critical (lc_unified_search) << string ("Account state is invalid. Could not on_start search!");
            return;
        }

        if (this.providers.is_empty ()) {
            var job = new JsonApiJob (this.account_state.account (), QLatin1String ("ocs/v2.php/search/providers"));
            GLib.Object.connect (job, &JsonApiJob.json_received, this, &Unified_search_results_list_model.on_fetch_providers_finished);
            job.on_start ();
        } else {
            start_search ();
        }
    }

    void Unified_search_results_list_model.on_fetch_providers_finished (QJsonDocument json, int status_code) {
        const var job = qobject_cast<JsonApiJob> (sender ());

        if (!job) {
            q_c_critical (lc_unified_search) << string ("Failed to fetch providers.").arg (this.search_term);
            this.error_string += _("Failed to fetch providers.") + '\n';
            /* emit */ error_string_changed ();
            return;
        }

        if (status_code != 200) {
            q_c_critical (lc_unified_search) << string ("%1 : Failed to fetch search providers for '%2'. Error : %3")
                                               .arg (status_code)
                                               .arg (this.search_term)
                                               .arg (job.error_string ());
            this.error_string +=
                _("Failed to fetch search providers for '%1'. Error : %2").arg (this.search_term).arg (job.error_string ())
                + '\n';
            /* emit */ error_string_changed ();
            return;
        }
        const var provider_list =
            json.object ().value (QStringLiteral ("ocs")).to_object ().value (QStringLiteral ("data")).to_variant ().to_list ();

        for (var provider : provider_list) {
            const var provider_map = provider.to_map ();
            const var id = provider_map[QStringLiteral ("id")].to_"";
            const var name = provider_map[QStringLiteral ("name")].to_"";
            if (!name.is_empty () && id != QStringLiteral ("talk-message-current")) {
                Unified_search_provider new_provider;
                new_provider._name = name;
                new_provider._id = id;
                new_provider._order = provider_map[QStringLiteral ("order")].to_int ();
                this.providers.insert (new_provider._id, new_provider);
            }
        }

        if (!this.providers.empty ()) {
            start_search ();
        }
    }

    void Unified_search_results_list_model.on_search_for_provider_finished (QJsonDocument json, int status_code) {
        Q_ASSERT (this.account_state && this.account_state.account ());

        const var job = qobject_cast<JsonApiJob> (sender ());

        if (!job) {
            q_c_critical (lc_unified_search) << string ("Search has failed for '%2'.").arg (this.search_term);
            this.error_string += _("Search has failed for '%2'.").arg (this.search_term) + '\n';
            /* emit */ error_string_changed ();
            return;
        }

        const var provider_id = job.property ("provider_id").to_"";

        if (provider_id.is_empty ()) {
            return;
        }

        if (!this.search_job_connections.is_empty ()) {
            this.search_job_connections.remove (provider_id);

            if (this.search_job_connections.is_empty ()) {
                /* emit */ is_search_in_progress_changed ();
            }
        }

        if (provider_id == this.current_fetch_more_in_progress_provider_id) {
            clear_current_fetch_more_in_progress_provider_id ();
        }

        if (status_code != 200) {
            q_c_critical (lc_unified_search) << string ("%1 : Search has failed for '%2'. Error : %3")
                                               .arg (status_code)
                                               .arg (this.search_term)
                                               .arg (job.error_string ());
            this.error_string +=
                _("Search has failed for '%1'. Error : %2").arg (this.search_term).arg (job.error_string ()) + '\n';
            /* emit */ error_string_changed ();
            return;
        }

        const var data = json.object ().value (QStringLiteral ("ocs")).to_object ().value (QStringLiteral ("data")).to_object ();
        if (!data.is_empty ()) {
            parse_results_for_provider (data, provider_id, job.property ("append_results").to_bool ());
        }
    }

    void Unified_search_results_list_model.start_search () {
        Q_ASSERT (this.account_state && this.account_state.account ());

        disconnect_and_clear_search_jobs ();

        if (!this.account_state || !this.account_state.account ()) {
            return;
        }

        if (!this.results.is_empty ()) {
            begin_reset_model ();
            this.results.clear ();
            end_reset_model ();
        }

        for (var provider : this.providers) {
            start_search_for_provider (provider._id);
        }
    }

    void Unified_search_results_list_model.start_search_for_provider (string provider_id, int32 cursor) {
        Q_ASSERT (this.account_state && this.account_state.account ());

        if (!this.account_state || !this.account_state.account ()) {
            return;
        }

        var job = new JsonApiJob (this.account_state.account (),
            QLatin1String ("ocs/v2.php/search/providers/%1/search").arg (provider_id));

        QUrlQuery parameters;
        parameters.add_query_item (QStringLiteral ("term"), this.search_term);
        if (cursor > 0) {
            parameters.add_query_item (QStringLiteral ("cursor"), string.number (cursor));
            job.set_property ("append_results", true);
        }
        job.set_property ("provider_id", provider_id);
        job.add_query_params (parameters);
        const var was_search_in_progress = is_search_in_progress ();
        this.search_job_connections.insert (provider_id,
            GLib.Object.connect (
                job, &JsonApiJob.json_received, this, &Unified_search_results_list_model.on_search_for_provider_finished));
        if (is_search_in_progress () && !was_search_in_progress) {
            /* emit */ is_search_in_progress_changed ();
        }
        job.on_start ();
    }

    void Unified_search_results_list_model.parse_results_for_provider (QJsonObject data, string provider_id, bool fetched_more) {
        const var cursor = data.value (QStringLiteral ("cursor")).to_int ();
        const var entries = data.value (QStringLiteral ("entries")).to_variant ().to_list ();

        var provider = this.providers[provider_id];

        if (provider._id.is_empty () && fetched_more) {
            this.providers.remove (provider_id);
            return;
        }

        if (entries.is_empty ()) {
            // we may have received false pagination information from the server, such as, we expect more
            // results available via pagination, but, there are no more left, so, we need to stop paginating for
            // this provider
            provider._is_paginated = false;

            if (fetched_more) {
                remove_fetch_more_trigger (provider._id);
            }

            return;
        }

        provider._is_paginated = data.value (QStringLiteral ("is_paginated")).to_bool ();
        provider._cursor = cursor;

        if (provider._page_size == -1) {
            provider._page_size = cursor;
        }

        if ( (provider._page_size != -1 && entries.size () < provider._page_size)
            || entries.size () < minimum_entres_number_to_show_load_more) {
            // for some providers we are still getting a non-null cursor and is_paginated true even thought
            // there are no more results to paginate
            provider._is_paginated = false;
        }

        GLib.Vector<Unified_search_result> new_entries;

        const var make_resource_url = [] (string resource_url, GLib.Uri account_url) {
            GLib.Uri final_resurce_url (resource_url);
            if (final_resurce_url.scheme ().is_empty () && account_url.scheme ().is_empty ()) {
                final_resurce_url = account_url;
                final_resurce_url.set_path (resource_url);
            }
            return final_resurce_url;
        };

        for (var entry : entries) {
            const var entry_map = entry.to_map ();
            if (entry_map.is_empty ()) {
                continue;
            }
            Unified_search_result result;
            result._provider_id = provider._id;
            result._order = provider._order;
            result._provider_name = provider._name;
            result._is_rounded = entry_map.value (QStringLiteral ("rounded")).to_bool ();
            result._title = entry_map.value (QStringLiteral ("title")).to_"";
            result._subline = entry_map.value (QStringLiteral ("subline")).to_"";

            const var resource_url = entry_map.value (QStringLiteral ("resource_url")).to_"";
            const var account_url = (this.account_state && this.account_state.account ()) ? this.account_state.account ().url () : GLib.Uri ();

            result._resource_url = make_resource_url (resource_url, account_url);
            result._icons = icons_from_thumbnail_and_fallback_icon (entry_map.value (QStringLiteral ("thumbnail_url")).to_"",
                entry_map.value (QStringLiteral ("icon")).to_"", account_url);

            new_entries.push_back (result);
        }

        if (fetched_more) {
            append_results_to_provider (new_entries, provider);
        } else {
            append_results (new_entries, provider);
        }
    }

    void Unified_search_results_list_model.append_results (GLib.Vector<Unified_search_result> results, Unified_search_provider provider) {
        if (provider._cursor > 0 && provider._is_paginated) {
            Unified_search_result fetch_more_trigger;
            fetch_more_trigger._provider_id = provider._id;
            fetch_more_trigger._provider_name = provider._name;
            fetch_more_trigger._order = provider._order;
            fetch_more_trigger._type = Unified_search_result.Type.Fetch_more_trigger;
            results.push_back (fetch_more_trigger);
        }

        if (this.results.is_empty ()) {
            begin_insert_rows ({}, 0, results.size () - 1);
            this.results = results;
            end_insert_rows ();
            return;
        }

        // insertion is done with sorting (first . by order, then . by name)
        const var it_to_insert_to = std.find_if (std.begin (this.results), std.end (this.results),
            [&provider] (Unified_search_result current) {
                // insert before other results of higher order when possible
                if (current._order > provider._order) {
                    return true;
                } else {
                    if (current._order == provider._order) {
                        // insert before results of higher string value when possible
                        return current._provider_name > provider._name;
                    }

                    return false;
                }
            });

        const var first = static_cast<int> (std.distance (std.begin (this.results), it_to_insert_to));
        const var last = first + results.size () - 1;

        begin_insert_rows ({}, first, last);
        std.copy (std.begin (results), std.end (results), std.inserter (this.results, it_to_insert_to));
        end_insert_rows ();
    }

    void Unified_search_results_list_model.append_results_to_provider (GLib.Vector<Unified_search_result> results, Unified_search_provider provider) {
        if (results.is_empty ()) {
            return;
        }

        const var provider_id = provider._id;
        /* we need to find the last result that is not a fetch-more-trigger or category-separator for the current
           provider */
        const var it_last_result_for_provider_reverse =
            std.find_if (std.rbegin (this.results), std.rend (this.results), [&provider_id] (Unified_search_result result) {
                return result._provider_id == provider_id && result._type == Unified_search_result.Type.Default;
            });

        if (it_last_result_for_provider_reverse != std.rend (this.results)) {
            // #1 Insert rows
            // convert reverse_iterator to iterator
            const var it_last_result_for_provider = (it_last_result_for_provider_reverse + 1).base ();
            const var first = static_cast<int> (std.distance (std.begin (this.results), it_last_result_for_provider + 1));
            const var last = first + results.size () - 1;
            begin_insert_rows ({}, first, last);
            std.copy (std.begin (results), std.end (results), std.inserter (this.results, it_last_result_for_provider + 1));
            end_insert_rows ();

            // #2 Remove the Fetch_more_trigger item if there are no more results to load for this provider
            if (!provider._is_paginated) {
                remove_fetch_more_trigger (provider_id);
            }
        }
    }

    void Unified_search_results_list_model.remove_fetch_more_trigger (string provider_id) {
        const var it_fetch_more_trigger_for_provider_reverse = std.find_if (
            std.rbegin (this.results),
            std.rend (this.results),
            [provider_id] (Unified_search_result result) {
                return result._provider_id == provider_id && result._type == Unified_search_result.Type.Fetch_more_trigger;
            });

        if (it_fetch_more_trigger_for_provider_reverse != std.rend (this.results)) {
            // convert reverse_iterator to iterator
            const var it_fetch_more_trigger_for_provider = (it_fetch_more_trigger_for_provider_reverse + 1).base ();

            if (it_fetch_more_trigger_for_provider != std.end (this.results)
                && it_fetch_more_trigger_for_provider != std.begin (this.results)) {
                const var erase_index = static_cast<int> (std.distance (std.begin (this.results), it_fetch_more_trigger_for_provider));
                Q_ASSERT (erase_index >= 0 && erase_index < static_cast<int> (this.results.size ()));
                begin_remove_rows ({}, erase_index, erase_index);
                this.results.erase (it_fetch_more_trigger_for_provider);
                end_remove_rows ();
            }
        }
    }

    void Unified_search_results_list_model.disconnect_and_clear_search_jobs () {
        for (var connection : this.search_job_connections) {
            if (connection) {
                GLib.Object.disconnect (connection);
            }
        }

        if (!this.search_job_connections.is_empty ()) {
            this.search_job_connections.clear ();
            /* emit */ is_search_in_progress_changed ();
        }
    }

    void Unified_search_results_list_model.clear_current_fetch_more_in_progress_provider_id () {
        if (!this.current_fetch_more_in_progress_provider_id.is_empty ()) {
            this.current_fetch_more_in_progress_provider_id.clear ();
            /* emit */ current_fetch_more_in_progress_provider_id_changed ();
        }
    }

    }
    