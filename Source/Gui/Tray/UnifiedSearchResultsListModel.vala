/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <algorithm>

// #include <QAbstract_list_model>
// #include <QDesktopServices>

// #pragma once

// #include <limits>

// #include <Qt_core>

namespace Occ {

/***********************************************************
@brief The Unified_search_results_list_model
@ingroup gui
Simple list model to provide the list view with data for the Unified Search results.
***********************************************************/

class Unified_search_results_list_model : QAbstract_list_model {

    Q_PROPERTY (bool is_search_in_progress READ is_search_in_progress NOTIFY is_search_in_progress_changed)
    Q_PROPERTY (string current_fetch_more_in_progress_provider_id READ current_fetch_more_in_progress_provider_id NOTIFY
            current_fetch_more_in_progress_provider_id_changed)
    Q_PROPERTY (string error_string READ error_string NOTIFY error_string_changed)
    Q_PROPERTY (string search_term READ search_term WRITE set_search_term NOTIFY search_term_changed)

    struct Unified_search_provider {
        string _id;
        string _name;
        int32 _cursor = -1; // current pagination value
        int32 _page_size = -1; // how many max items per step of pagination
        bool _is_paginated = false;
        int32 _order = std.numeric_limits<int32>.max (); // sorting order (smaller number has bigger priority)
    };

public:
    enum Data_role {
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

    Unified_search_results_list_model (AccountState *account_state, GLib.Object *parent = nullptr);

    QVariant data (QModelIndex &index, int role) const override;
    int row_count (QModelIndex &parent = QModelIndex ()) const override;

    bool is_search_in_progress ();

    string current_fetch_more_in_progress_provider_id ();
    string search_term ();
    string error_string ();

    Q_INVOKABLE void result_clicked (string &provider_id, QUrl &resource_url) const;
    Q_INVOKABLE void fetch_more_trigger_clicked (string &provider_id);

    QHash<int, QByteArray> role_names () const override;

private:
    void start_search ();
    void start_search_for_provider (string &provider_id, int32 cursor = -1);

    void parse_results_for_provider (QJsonObject &data, string &provider_id, bool fetched_more = false);

    // append initial search results to the list
    void append_results (QVector<Unified_search_result> results, Unified_search_provider &provider);

    // append pagination results to existing results from the initial search
    void append_results_to_provider (QVector<Unified_search_result> &results, Unified_search_provider &provider);

    void remove_fetch_more_trigger (string &provider_id);

    void disconnect_and_clear_search_jobs ();

    void clear_current_fetch_more_in_progress_provider_id ();

signals:
    void current_fetch_more_in_progress_provider_id_changed ();
    void is_search_in_progress_changed ();
    void error_string_changed ();
    void search_term_changed ();

public slots:
    void set_search_term (string &term);

private slots:
    void slot_search_term_editing_finished ();
    void slot_fetch_providers_finished (QJsonDocument &json, int status_code);
    void slot_search_for_provider_finished (QJsonDocument &json, int status_code);

private:
    QMap<string, Unified_search_provider> _providers;
    QVector<Unified_search_result> _results;

    string _search_term;
    string _error_string;

    string _current_fetch_more_in_progress_provider_id;

    QMap<string, QMetaObject.Connection> _search_job_connections;

    QTimer _unified_search_text_editing_finished_timer;

    AccountState *_account_state = nullptr;
};
}








namespace {
    string image_placeholder_url_for_provider_id (string &provider_id) {
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
    
    string local_icon_path_from_icon_prefix (string &icon_name_with_prefix) {
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
    
    string icon_url_for_default_icon_name (string &default_icon_name) {
        const QUrl url_for_icon{default_icon_name};
    
        if (url_for_icon.is_valid () && !url_for_icon.scheme ().is_empty ()) {
            return default_icon_name;
        }
    
        if (default_icon_name.starts_with (QStringLiteral ("icon-"))) {
            const auto parts = default_icon_name.split (QLatin1Char ('-'));
    
            if (parts.size () > 1) {
                const string icon_file_path = QStringLiteral (":/client/theme/") + parts[1] + QStringLiteral (".svg");
    
                if (QFile.exists (icon_file_path)) {
                    return icon_file_path;
                }
    
                const string black_icon_file_path = QStringLiteral (":/client/theme/black/") + parts[1] + QStringLiteral (".svg");
    
                if (QFile.exists (black_icon_file_path)) {
                    return black_icon_file_path;
                }
            }
    
            const auto icon_name_from_icon_prefix = local_icon_path_from_icon_prefix (default_icon_name);
    
            if (!icon_name_from_icon_prefix.is_empty ()) {
                return icon_name_from_icon_prefix;
            }
        }
    
        return QStringLiteral (":/client/theme/change.svg");
    }
    
    string generate_url_for_thumbnail (string &thumbnail_url, QUrl &server_url) {
        auto server_url_copy = server_url;
        auto thumbnail_url_copy = thumbnail_url;
    
        if (thumbnail_url_copy.starts_with (QLatin1Char ('/')) || thumbnail_url_copy.starts_with (QLatin1Char ('\\'))) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const QStringList thumbnail_url_copy_splitted = thumbnail_url_copy.contains (QLatin1Char ('?'))
                ? thumbnail_url_copy.split (QLatin1Char ('?'), Qt.Skip_empty_parts)
                : QStringList{thumbnail_url_copy};
            Q_ASSERT (!thumbnail_url_copy_splitted.is_empty ());
            server_url_copy.set_path (thumbnail_url_copy_splitted[0]);
            thumbnail_url_copy = server_url_copy.to_string ();
            if (thumbnail_url_copy_splitted.size () > 1) {
                thumbnail_url_copy += QLatin1Char ('?') + thumbnail_url_copy_splitted[1];
            }
        }
    
        return thumbnail_url_copy;
    }
    
    string generate_url_for_icon (string &fallack_icon, QUrl &server_url) {
        auto server_url_copy = server_url;
    
        auto fallack_icon_copy = fallack_icon;
    
        if (fallack_icon_copy.starts_with (QLatin1Char ('/')) || fallack_icon_copy.starts_with (QLatin1Char ('\\'))) {
            // relative image resource URL, just needs some concatenation with current server URL
            // some icons may contain parameters after (?)
            const QStringList fallack_icon_path_splitted =
                fallack_icon_copy.contains (QLatin1Char ('?')) ? fallack_icon_copy.split (QLatin1Char ('?')) : QStringList{fallack_icon_copy};
            Q_ASSERT (!fallack_icon_path_splitted.is_empty ());
            server_url_copy.set_path (fallack_icon_path_splitted[0]);
            fallack_icon_copy = server_url_copy.to_string ();
            if (fallack_icon_path_splitted.size () > 1) {
                fallack_icon_copy += QLatin1Char ('?') + fallack_icon_path_splitted[1];
            }
        } else if (!fallack_icon_copy.is_empty ()) {
            // could be one of names for standard icons (e.g. icon-mail)
            const auto default_icon_url = icon_url_for_default_icon_name (fallack_icon_copy);
            if (!default_icon_url.is_empty ()) {
                fallack_icon_copy = default_icon_url;
            }
        }
    
        return fallack_icon_copy;
    }
    
    string icons_from_thumbnail_and_fallback_icon (string &thumbnail_url, string &fallack_icon, QUrl &server_url) {
        if (thumbnail_url.is_empty () && fallack_icon.is_empty ()) {
            return {};
        }
    
        if (server_url.is_empty ()) {
            const QStringList list_images = {thumbnail_url, fallack_icon};
            return list_images.join (QLatin1Char (';'));
        }
    
        const auto url_for_thumbnail = generate_url_for_thumbnail (thumbnail_url, server_url);
        const auto url_for_fallack_icon = generate_url_for_icon (fallack_icon, server_url);
    
        if (url_for_thumbnail.is_empty () && !url_for_fallack_icon.is_empty ()) {
            return url_for_fallack_icon;
        }
    
        if (!url_for_thumbnail.is_empty () && url_for_fallack_icon.is_empty ()) {
            return url_for_thumbnail;
        }
    
        const QStringList list_images{url_for_thumbnail, url_for_fallack_icon};
        return list_images.join (QLatin1Char (';'));
    }
    
    constexpr int search_term_editing_finished_search_start_delay = 800;
    
    // server-side bug of returning the cursor > 0 and is_paginated == 'true', using '5' as it is done on Android client's end now
    constexpr int minimum_entres_number_to_show_load_more = 5;

    Unified_search_results_list_model.Unified_search_results_list_model (AccountState *account_state, GLib.Object *parent)
        : QAbstract_list_model (parent)
        , _account_state (account_state) {
    }
    
    QVariant Unified_search_results_list_model.data (QModelIndex &index, int role) {
        Q_ASSERT (check_index (index, QAbstractItemModel.Check_index_option.Index_is_valid));
    
        switch (role) {
        case Provider_name_role:
            return _results.at (index.row ())._provider_name;
        case Provider_id_role:
            return _results.at (index.row ())._provider_id;
        case Image_placeholder_role:
            return image_placeholder_url_for_provider_id (_results.at (index.row ())._provider_id);
        case Icons_role:
            return _results.at (index.row ())._icons;
        case Title_role:
            return _results.at (index.row ())._title;
        case Subline_role:
            return _results.at (index.row ())._subline;
        case Resource_url_role:
            return _results.at (index.row ())._resource_url;
        case Rounded_role:
            return _results.at (index.row ())._is_rounded;
        case Type_role:
            return _results.at (index.row ())._type;
        case Type_as_string_role:
            return Unified_search_result.type_as_string (_results.at (index.row ())._type);
        }
    
        return {};
    }
    
    int Unified_search_results_list_model.row_count (QModelIndex &parent) {
        if (parent.is_valid ()) {
            return 0;
        }
    
        return _results.size ();
    }
    
    QHash<int, QByteArray> Unified_search_results_list_model.role_names () {
        auto roles = QAbstract_list_model.role_names ();
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
        return _search_term;
    }
    
    string Unified_search_results_list_model.error_string () {
        return _error_string;
    }
    
    string Unified_search_results_list_model.current_fetch_more_in_progress_provider_id () {
        return _current_fetch_more_in_progress_provider_id;
    }
    
    void Unified_search_results_list_model.set_search_term (string &term) {
        if (term == _search_term) {
            return;
        }
    
        _search_term = term;
        emit search_term_changed ();
    
        if (!_error_string.is_empty ()) {
            _error_string.clear ();
            emit error_string_changed ();
        }
    
        disconnect_and_clear_search_jobs ();
    
        clear_current_fetch_more_in_progress_provider_id ();
    
        disconnect (&_unified_search_text_editing_finished_timer, &QTimer.timeout, this,
            &Unified_search_results_list_model.slot_search_term_editing_finished);
    
        if (_unified_search_text_editing_finished_timer.is_active ()) {
            _unified_search_text_editing_finished_timer.stop ();
        }
    
        if (!_search_term.is_empty ()) {
            _unified_search_text_editing_finished_timer.set_interval (search_term_editing_finished_search_start_delay);
            connect (&_unified_search_text_editing_finished_timer, &QTimer.timeout, this,
                &Unified_search_results_list_model.slot_search_term_editing_finished);
            _unified_search_text_editing_finished_timer.start ();
        }
    
        if (!_results.is_empty ()) {
            begin_reset_model ();
            _results.clear ();
            end_reset_model ();
        }
    }
    
    bool Unified_search_results_list_model.is_search_in_progress () {
        return !_search_job_connections.is_empty ();
    }
    
    void Unified_search_results_list_model.result_clicked (string &provider_id, QUrl &resource_url) {
        const QUrlQuery url_query{resource_url};
        const auto dir = url_query.query_item_value (QStringLiteral ("dir"), QUrl.Component_formatting_option.Fully_decoded);
        const auto file_name =
            url_query.query_item_value (QStringLiteral ("scrollto"), QUrl.Component_formatting_option.Fully_decoded);
    
        if (provider_id.contains (QStringLiteral ("file"), Qt.CaseInsensitive) && !dir.is_empty () && !file_name.is_empty ()) {
            if (!_account_state || !_account_state.account ()) {
                return;
            }
    
            const string relative_path = dir + QLatin1Char ('/') + file_name;
            const auto local_files =
                FolderMan.instance ().find_file_in_local_folders (QFileInfo (relative_path).path (), _account_state.account ());
    
            if (!local_files.is_empty ()) {
                q_c_info (lc_unified_search) << "Opening file:" << local_files.const_first ();
                QDesktopServices.open_url (QUrl.from_local_file (local_files.const_first ()));
                return;
            }
        }
        Utility.open_browser (resource_url);
    }
    
    void Unified_search_results_list_model.fetch_more_trigger_clicked (string &provider_id) {
        if (is_search_in_progress () || !_current_fetch_more_in_progress_provider_id.is_empty ()) {
            return;
        }
    
        const auto provider_info = _providers.value (provider_id, {});
    
        if (!provider_info._id.is_empty () && provider_info._id == provider_id && provider_info._is_paginated) {
            // Load more items
            _current_fetch_more_in_progress_provider_id = provider_id;
            emit current_fetch_more_in_progress_provider_id_changed ();
            start_search_for_provider (provider_id, provider_info._cursor);
        }
    }
    
    void Unified_search_results_list_model.slot_search_term_editing_finished () {
        disconnect (&_unified_search_text_editing_finished_timer, &QTimer.timeout, this,
            &Unified_search_results_list_model.slot_search_term_editing_finished);
    
        if (!_account_state || !_account_state.account ()) {
            q_c_critical (lc_unified_search) << string ("Account state is invalid. Could not start search!");
            return;
        }
    
        if (_providers.is_empty ()) {
            auto job = new JsonApiJob (_account_state.account (), QLatin1String ("ocs/v2.php/search/providers"));
            GLib.Object.connect (job, &JsonApiJob.json_received, this, &Unified_search_results_list_model.slot_fetch_providers_finished);
            job.start ();
        } else {
            start_search ();
        }
    }
    
    void Unified_search_results_list_model.slot_fetch_providers_finished (QJsonDocument &json, int status_code) {
        const auto job = qobject_cast<JsonApiJob> (sender ());
    
        if (!job) {
            q_c_critical (lc_unified_search) << string ("Failed to fetch providers.").arg (_search_term);
            _error_string += tr ("Failed to fetch providers.") + QLatin1Char ('\n');
            emit error_string_changed ();
            return;
        }
    
        if (status_code != 200) {
            q_c_critical (lc_unified_search) << string ("%1 : Failed to fetch search providers for '%2'. Error : %3")
                                               .arg (status_code)
                                               .arg (_search_term)
                                               .arg (job.error_string ());
            _error_string +=
                tr ("Failed to fetch search providers for '%1'. Error : %2").arg (_search_term).arg (job.error_string ())
                + QLatin1Char ('\n');
            emit error_string_changed ();
            return;
        }
        const auto provider_list =
            json.object ().value (QStringLiteral ("ocs")).to_object ().value (QStringLiteral ("data")).to_variant ().to_list ();
    
        for (auto &provider : provider_list) {
            const auto provider_map = provider.to_map ();
            const auto id = provider_map[QStringLiteral ("id")].to_string ();
            const auto name = provider_map[QStringLiteral ("name")].to_string ();
            if (!name.is_empty () && id != QStringLiteral ("talk-message-current")) {
                Unified_search_provider new_provider;
                new_provider._name = name;
                new_provider._id = id;
                new_provider._order = provider_map[QStringLiteral ("order")].to_int ();
                _providers.insert (new_provider._id, new_provider);
            }
        }
    
        if (!_providers.empty ()) {
            start_search ();
        }
    }
    
    void Unified_search_results_list_model.slot_search_for_provider_finished (QJsonDocument &json, int status_code) {
        Q_ASSERT (_account_state && _account_state.account ());
    
        const auto job = qobject_cast<JsonApiJob> (sender ());
    
        if (!job) {
            q_c_critical (lc_unified_search) << string ("Search has failed for '%2'.").arg (_search_term);
            _error_string += tr ("Search has failed for '%2'.").arg (_search_term) + QLatin1Char ('\n');
            emit error_string_changed ();
            return;
        }
    
        const auto provider_id = job.property ("provider_id").to_string ();
    
        if (provider_id.is_empty ()) {
            return;
        }
    
        if (!_search_job_connections.is_empty ()) {
            _search_job_connections.remove (provider_id);
    
            if (_search_job_connections.is_empty ()) {
                emit is_search_in_progress_changed ();
            }
        }
    
        if (provider_id == _current_fetch_more_in_progress_provider_id) {
            clear_current_fetch_more_in_progress_provider_id ();
        }
    
        if (status_code != 200) {
            q_c_critical (lc_unified_search) << string ("%1 : Search has failed for '%2'. Error : %3")
                                               .arg (status_code)
                                               .arg (_search_term)
                                               .arg (job.error_string ());
            _error_string +=
                tr ("Search has failed for '%1'. Error : %2").arg (_search_term).arg (job.error_string ()) + QLatin1Char ('\n');
            emit error_string_changed ();
            return;
        }
    
        const auto data = json.object ().value (QStringLiteral ("ocs")).to_object ().value (QStringLiteral ("data")).to_object ();
        if (!data.is_empty ()) {
            parse_results_for_provider (data, provider_id, job.property ("append_results").to_bool ());
        }
    }
    
    void Unified_search_results_list_model.start_search () {
        Q_ASSERT (_account_state && _account_state.account ());
    
        disconnect_and_clear_search_jobs ();
    
        if (!_account_state || !_account_state.account ()) {
            return;
        }
    
        if (!_results.is_empty ()) {
            begin_reset_model ();
            _results.clear ();
            end_reset_model ();
        }
    
        for (auto &provider : _providers) {
            start_search_for_provider (provider._id);
        }
    }
    
    void Unified_search_results_list_model.start_search_for_provider (string &provider_id, int32 cursor) {
        Q_ASSERT (_account_state && _account_state.account ());
    
        if (!_account_state || !_account_state.account ()) {
            return;
        }
    
        auto job = new JsonApiJob (_account_state.account (),
            QLatin1String ("ocs/v2.php/search/providers/%1/search").arg (provider_id));
    
        QUrlQuery params;
        params.add_query_item (QStringLiteral ("term"), _search_term);
        if (cursor > 0) {
            params.add_query_item (QStringLiteral ("cursor"), string.number (cursor));
            job.set_property ("append_results", true);
        }
        job.set_property ("provider_id", provider_id);
        job.add_query_params (params);
        const auto was_search_in_progress = is_search_in_progress ();
        _search_job_connections.insert (provider_id,
            GLib.Object.connect (
                job, &JsonApiJob.json_received, this, &Unified_search_results_list_model.slot_search_for_provider_finished));
        if (is_search_in_progress () && !was_search_in_progress) {
            emit is_search_in_progress_changed ();
        }
        job.start ();
    }
    
    void Unified_search_results_list_model.parse_results_for_provider (QJsonObject &data, string &provider_id, bool fetched_more) {
        const auto cursor = data.value (QStringLiteral ("cursor")).to_int ();
        const auto entries = data.value (QStringLiteral ("entries")).to_variant ().to_list ();
    
        auto &provider = _providers[provider_id];
    
        if (provider._id.is_empty () && fetched_more) {
            _providers.remove (provider_id);
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
    
        QVector<Unified_search_result> new_entries;
    
        const auto make_resource_url = [] (string &resource_url, QUrl &account_url) {
            QUrl final_resurce_url (resource_url);
            if (final_resurce_url.scheme ().is_empty () && account_url.scheme ().is_empty ()) {
                final_resurce_url = account_url;
                final_resurce_url.set_path (resource_url);
            }
            return final_resurce_url;
        };
    
        for (auto &entry : entries) {
            const auto entry_map = entry.to_map ();
            if (entry_map.is_empty ()) {
                continue;
            }
            Unified_search_result result;
            result._provider_id = provider._id;
            result._order = provider._order;
            result._provider_name = provider._name;
            result._is_rounded = entry_map.value (QStringLiteral ("rounded")).to_bool ();
            result._title = entry_map.value (QStringLiteral ("title")).to_string ();
            result._subline = entry_map.value (QStringLiteral ("subline")).to_string ();
    
            const auto resource_url = entry_map.value (QStringLiteral ("resource_url")).to_string ();
            const auto account_url = (_account_state && _account_state.account ()) ? _account_state.account ().url () : QUrl ();
    
            result._resource_url = make_resource_url (resource_url, account_url);
            result._icons = icons_from_thumbnail_and_fallback_icon (entry_map.value (QStringLiteral ("thumbnail_url")).to_string (),
                entry_map.value (QStringLiteral ("icon")).to_string (), account_url);
    
            new_entries.push_back (result);
        }
    
        if (fetched_more) {
            append_results_to_provider (new_entries, provider);
        } else {
            append_results (new_entries, provider);
        }
    }
    
    void Unified_search_results_list_model.append_results (QVector<Unified_search_result> results, Unified_search_provider &provider) {
        if (provider._cursor > 0 && provider._is_paginated) {
            Unified_search_result fetch_more_trigger;
            fetch_more_trigger._provider_id = provider._id;
            fetch_more_trigger._provider_name = provider._name;
            fetch_more_trigger._order = provider._order;
            fetch_more_trigger._type = Unified_search_result.Type.Fetch_more_trigger;
            results.push_back (fetch_more_trigger);
        }
    
        if (_results.is_empty ()) {
            begin_insert_rows ({}, 0, results.size () - 1);
            _results = results;
            end_insert_rows ();
            return;
        }
    
        // insertion is done with sorting (first . by order, then . by name)
        const auto it_to_insert_to = std.find_if (std.begin (_results), std.end (_results),
            [&provider] (Unified_search_result &current) {
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
    
        const auto first = static_cast<int> (std.distance (std.begin (_results), it_to_insert_to));
        const auto last = first + results.size () - 1;
    
        begin_insert_rows ({}, first, last);
        std.copy (std.begin (results), std.end (results), std.inserter (_results, it_to_insert_to));
        end_insert_rows ();
    }
    
    void Unified_search_results_list_model.append_results_to_provider (QVector<Unified_search_result> &results, Unified_search_provider &provider) {
        if (results.is_empty ()) {
            return;
        }
    
        const auto provider_id = provider._id;
        /* we need to find the last result that is not a fetch-more-trigger or category-separator for the current
           provider */
        const auto it_last_result_for_provider_reverse =
            std.find_if (std.rbegin (_results), std.rend (_results), [&provider_id] (Unified_search_result &result) {
                return result._provider_id == provider_id && result._type == Unified_search_result.Type.Default;
            });
    
        if (it_last_result_for_provider_reverse != std.rend (_results)) {
            // #1 Insert rows
            // convert reverse_iterator to iterator
            const auto it_last_result_for_provider = (it_last_result_for_provider_reverse + 1).base ();
            const auto first = static_cast<int> (std.distance (std.begin (_results), it_last_result_for_provider + 1));
            const auto last = first + results.size () - 1;
            begin_insert_rows ({}, first, last);
            std.copy (std.begin (results), std.end (results), std.inserter (_results, it_last_result_for_provider + 1));
            end_insert_rows ();
    
            // #2 Remove the Fetch_more_trigger item if there are no more results to load for this provider
            if (!provider._is_paginated) {
                remove_fetch_more_trigger (provider_id);
            }
        }
    }
    
    void Unified_search_results_list_model.remove_fetch_more_trigger (string &provider_id) {
        const auto it_fetch_more_trigger_for_provider_reverse = std.find_if (
            std.rbegin (_results),
            std.rend (_results),
            [provider_id] (Unified_search_result &result) {
                return result._provider_id == provider_id && result._type == Unified_search_result.Type.Fetch_more_trigger;
            });
    
        if (it_fetch_more_trigger_for_provider_reverse != std.rend (_results)) {
            // convert reverse_iterator to iterator
            const auto it_fetch_more_trigger_for_provider = (it_fetch_more_trigger_for_provider_reverse + 1).base ();
    
            if (it_fetch_more_trigger_for_provider != std.end (_results)
                && it_fetch_more_trigger_for_provider != std.begin (_results)) {
                const auto erase_index = static_cast<int> (std.distance (std.begin (_results), it_fetch_more_trigger_for_provider));
                Q_ASSERT (erase_index >= 0 && erase_index < static_cast<int> (_results.size ()));
                begin_remove_rows ({}, erase_index, erase_index);
                _results.erase (it_fetch_more_trigger_for_provider);
                end_remove_rows ();
            }
        }
    }
    
    void Unified_search_results_list_model.disconnect_and_clear_search_jobs () {
        for (auto &connection : _search_job_connections) {
            if (connection) {
                GLib.Object.disconnect (connection);
            }
        }
    
        if (!_search_job_connections.is_empty ()) {
            _search_job_connections.clear ();
            emit is_search_in_progress_changed ();
        }
    }
    
    void Unified_search_results_list_model.clear_current_fetch_more_in_progress_provider_id () {
        if (!_current_fetch_more_in_progress_provider_id.is_empty ()) {
            _current_fetch_more_in_progress_provider_id.clear ();
            emit current_fetch_more_in_progress_provider_id_changed ();
        }
    }
    
    }
    