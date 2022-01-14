/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariantMap>
// #include <QLoggingCategory>
// #include <QUrl>

// #include <QDebug>

// #include <QVariantMap>
// #include <QStringList>
// #include <QMimeDatabase>

namespace Occ {


enum Push_notification_type {
    None = 0,
    Files = 1,
    Activities = 2,
    Notifications = 4
};
Q_DECLARE_FLAGS (Push_notification_types, Push_notification_type)
Q_DECLARE_OPERATORS_FOR_FLAGS (Push_notification_types)

/***********************************************************
@brief The Capabilities class represents the capabilities of an own_cloud
server
@ingroup libsync
***********************************************************/
class Capabilities {
public:
    Capabilities (QVariantMap &capabilities);

    bool share_a_p_i ();
    bool share_email_password_enabled ();
    bool share_email_password_enforced ();
    bool share_public_link ();
    bool share_public_link_allow_upload ();
    bool share_public_link_supports_upload_only ();
    bool share_public_link_ask_optional_password ();
    bool share_public_link_enforce_password ();
    bool share_public_link_enforce_expire_date ();
    int share_public_link_expire_date_days ();
    bool share_internal_enforce_expire_date ();
    int share_internal_expire_date_days ();
    bool share_remote_enforce_expire_date ();
    int share_remote_expire_date_days ();
    bool share_public_link_multiple ();
    bool share_resharing ();
    int share_default_permissions ();
    bool chunking_ng ();
    bool bulk_upload ();
    bool user_status ();
    bool user_status_supports_emoji ();

    /// Returns which kind of push notfications are available
    Push_notification_types available_push_notifications ();

    /// Websocket url for files push notifications if available
    QUrl push_notifications_web_socket_url ();

    /// disable parallel upload in chunking
    bool chunking_parallel_upload_disabled ();

    /// Whether the "privatelink" DAV property is available
    bool private_link_property_available ();

    /// returns true if the capabilities report notifications
    bool notifications_available ();

    /// returns true if the server supports client side encryption
    bool client_side_encryption_available ();

    /// returns true if the capabilities are loaded already.
    bool is_valid ();

    /// return true if the activity app is enabled
    bool has_activities ();

    /***********************************************************
    Returns the checksum types the server understands.
    
    When the client uses one of these checksumming algorithms in
    the OC-Checksum header of a file upload, the server 
    it to validate that data was tr
    
    Path : checksums/supported_types
    Default : []
    Possible entries : "Adler32", "MD5", "SHA1"
    ***********************************************************/
    QList<QByteArray> supported_checksum_types ();

    /***********************************************************
    The checksum algorithm that the server recommends for file uploads.
    This is just a preference, any algorithm listed in supported_types may be used.
    
    Path : checksums/preferred_upload_type
    Default : empty, meaning "no preference"
    Possible values : empty or any of the supported_types
    ***********************************************************/
    QByteArray preferred_upload_checksum_type ();

    /***********************************************************
    Helper that returns the preferred_upload_checksum_type () if set, or one
    of the supported_checksum_types () if it isn't. May return an empty
    QByteArray if no checksum types are supported.
    ***********************************************************/
    QByteArray upload_checksum_type ();

    /***********************************************************
    List of HTTP error codes should be guaranteed to eventually reset
    failing chunked uploads.
    
    The resetting works by tracking UploadInfo.error_count.
    
    Note that other error codes than the ones listed here may reset the
    upload as well.
    
    Motivation : See #5344. They should always be reset on 
    checksum err
    unusual error codes such as 503.

    Path : dav/http_error_codes_that_reset_failing_chunked_uploads
    Default : []
    Example : [503, 500]
    ***********************************************************/
    QList<int> http_error_codes_that_reset_failing_chunked_uploads ();

    /***********************************************************
    Regex that, if contained in a filename, will result in it not being uploaded.
    
    For servers older than 8.1.0 it defaults to [\\:?*"<>|]
    For servers >= that version, it defaults to the empty rege
    will indicate invalid characters through an upload error)

    Note that it just needs to be contained. The regex [ab] is contained in "car".
    ***********************************************************/
    string invalid_filename_regex ();

    /***********************************************************
    return the list of filename that should not be uploaded
    ***********************************************************/
    QStringList blacklisted_files ();

    /***********************************************************
    Whether conflict files should remain local (default) or should be uploaded.
    ***********************************************************/
    bool upload_conflict_files ();

    // Direct Editing
    void add_direct_editor (Direct_editor* direct_editor);
    Direct_editor* get_direct_editor_for_mimetype (QMime_type &mime_type);
    Direct_editor* get_direct_editor_for_optional_mimetype (QMime_type &mime_type);

private:
    QVariantMap _capabilities;

    QList<Direct_editor> _direct_editors;
};

/*-------------------------------------------------------------------------------------*/

class Direct_editor : GLib.Object {
public:
    Direct_editor (string &id, string &name, GLib.Object* parent = nullptr);

    void add_mimetype (QByteArray &mime_type);
    void add_optional_mimetype (QByteArray &mime_type);

    bool has_mimetype (QMime_type &mime_type);
    bool has_optional_mimetype (QMime_type &mime_type);

    string id ();
    string name ();

    QList<QByteArray> mime_types ();
    QList<QByteArray> optional_mime_types ();

private:
    string _id;
    string _name;

    QList<QByteArray> _mime_types;
    QList<QByteArray> _optional_mime_types;
};

    Capabilities.Capabilities (QVariantMap &capabilities)
        : _capabilities (capabilities) {
    }
    
    bool Capabilities.share_a_p_i () {
        if (_capabilities["files_sharing"].to_map ().contains ("api_enabled")) {
            return _capabilities["files_sharing"].to_map ()["api_enabled"].to_bool ();
        } else {
            // This was later added so if it is not present just assume the API is enabled.
            return true;
        }
    }
    
    bool Capabilities.share_email_password_enabled () {
        return _capabilities["files_sharing"].to_map ()["sharebymail"].to_map ()["password"].to_map ()["enabled"].to_bool ();
    }
    
    bool Capabilities.share_email_password_enforced () {
        return _capabilities["files_sharing"].to_map ()["sharebymail"].to_map ()["password"].to_map ()["enforced"].to_bool ();
    }
    
    bool Capabilities.share_public_link () {
        if (_capabilities["files_sharing"].to_map ().contains ("public")) {
            return share_a_p_i () && _capabilities["files_sharing"].to_map ()["public"].to_map ()["enabled"].to_bool ();
        } else {
            // This was later added so if it is not present just assume that link sharing is enabled.
            return true;
        }
    }
    
    bool Capabilities.share_public_link_allow_upload () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["upload"].to_bool ();
    }
    
    bool Capabilities.share_public_link_supports_upload_only () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["supports_upload_only"].to_bool ();
    }
    
    bool Capabilities.share_public_link_ask_optional_password () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["password"].to_map ()["ask_for_optional_password"].to_bool ();
    }
    
    bool Capabilities.share_public_link_enforce_password () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["password"].to_map ()["enforced"].to_bool ();
    }
    
    bool Capabilities.share_public_link_enforce_expire_date () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date"].to_map ()["enforced"].to_bool ();
    }
    
    int Capabilities.share_public_link_expire_date_days () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date"].to_map ()["days"].to_int ();
    }
    
    bool Capabilities.share_internal_enforce_expire_date () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_internal"].to_map ()["enforced"].to_bool ();
    }
    
    int Capabilities.share_internal_expire_date_days () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_internal"].to_map ()["days"].to_int ();
    }
    
    bool Capabilities.share_remote_enforce_expire_date () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_remote"].to_map ()["enforced"].to_bool ();
    }
    
    int Capabilities.share_remote_expire_date_days () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_remote"].to_map ()["days"].to_int ();
    }
    
    bool Capabilities.share_public_link_multiple () {
        return _capabilities["files_sharing"].to_map ()["public"].to_map ()["multiple"].to_bool ();
    }
    
    bool Capabilities.share_resharing () {
        return _capabilities["files_sharing"].to_map ()["resharing"].to_bool ();
    }
    
    int Capabilities.share_default_permissions () {
        if (_capabilities["files_sharing"].to_map ().contains ("default_permissions")) {
            return _capabilities["files_sharing"].to_map ()["default_permissions"].to_int ();
        }
    
        return {};
    }
    
    bool Capabilities.client_side_encryption_available () {
        auto it = _capabilities.const_find (QStringLiteral ("end-to-end-encryption"));
        if (it == _capabilities.const_end ()) {
            return false;
        }
    
        const auto properties = (*it).to_map ();
        const auto enabled = properties.value (QStringLiteral ("enabled"), false).to_bool ();
        if (!enabled) {
            return false;
        }
    
        const auto version = properties.value (QStringLiteral ("api-version"), "1.0").to_byte_array ();
        q_c_info (lc_server_capabilities) << "E2EE API version:" << version;
        const auto splitted_version = version.split ('.');
    
        bool ok = false;
        const auto major = !splitted_version.is_empty () ? splitted_version.at (0).to_int (&ok) : 0;
        if (!ok) {
            q_c_warning (lc_server_capabilities) << "Didn't understand version scheme (major), E2EE disabled";
            return false;
        }
    
        ok = false;
        const auto minor = splitted_version.size () > 1 ? splitted_version.at (1).to_int (&ok) : 0;
        if (!ok) {
            q_c_warning (lc_server_capabilities) << "Didn't understand version scheme (minor), E2EE disabled";
            return false;
        }
    
        return major == 1 && minor >= 1;
    }
    
    bool Capabilities.notifications_available () {
        // We require the OCS style API in 9.x, can't deal with the REST one only found in 8.2
        return _capabilities.contains ("notifications") && _capabilities["notifications"].to_map ().contains ("ocs-endpoints");
    }
    
    bool Capabilities.is_valid () {
        return !_capabilities.is_empty ();
    }
    
    bool Capabilities.has_activities () {
        return _capabilities.contains ("activity");
    }
    
    QList<QByteArray> Capabilities.supported_checksum_types () {
        QList<QByteArray> list;
        foreach (auto &t, _capabilities["checksums"].to_map ()["supported_types"].to_list ()) {
            list.push_back (t.to_byte_array ());
        }
        return list;
    }
    
    QByteArray Capabilities.preferred_upload_checksum_type () {
        return q_environment_variable ("OWNCLOUD_CONTENT_CHECKSUM_TYPE",
                                    _capabilities.value (QStringLiteral ("checksums")).to_map ()
                                    .value (QStringLiteral ("preferred_upload_type"), QStringLiteral ("SHA1")).to_string ()).to_utf8 ();
    }
    
    QByteArray Capabilities.upload_checksum_type () {
        QByteArray preferred = preferred_upload_checksum_type ();
        if (!preferred.is_empty ())
            return preferred;
        QList<QByteArray> supported = supported_checksum_types ();
        if (!supported.is_empty ())
            return supported.first ();
        return QByteArray ();
    }
    
    bool Capabilities.chunking_ng () {
        static const auto chunkng = qgetenv ("OWNCLOUD_CHUNKING_NG");
        if (chunkng == "0")
            return false;
        if (chunkng == "1")
            return true;
        return _capabilities["dav"].to_map ()["chunking"].to_byte_array () >= "1.0";
    }
    
    bool Capabilities.bulk_upload () {
        return _capabilities["dav"].to_map ()["bulkupload"].to_byte_array () >= "1.0";
    }
    
    bool Capabilities.user_status () {
        if (!_capabilities.contains ("user_status")) {
            return false;
        }
        const auto user_status_map = _capabilities["user_status"].to_map ();
        return user_status_map.value ("enabled", false).to_bool ();
    }
    
    bool Capabilities.user_status_supports_emoji () {
        if (!user_status ()) {
            return false;
        }
        const auto user_status_map = _capabilities["user_status"].to_map ();
        return user_status_map.value ("supports_emoji", false).to_bool ();
    }
    
    Push_notification_types Capabilities.available_push_notifications () {
        if (!_capabilities.contains ("notify_push")) {
            return Push_notification_type.None;
        }
    
        const auto types = _capabilities["notify_push"].to_map ()["type"].to_string_list ();
        Push_notification_types push_notification_types;
    
        if (types.contains ("files")) {
            push_notification_types.set_flag (Push_notification_type.Files);
        }
    
        if (types.contains ("activities")) {
            push_notification_types.set_flag (Push_notification_type.Activities);
        }
    
        if (types.contains ("notifications")) {
            push_notification_types.set_flag (Push_notification_type.Notifications);
        }
    
        return push_notification_types;
    }
    
    QUrl Capabilities.push_notifications_web_socket_url () {
        const auto websocket = _capabilities["notify_push"].to_map ()["endpoints"].to_map ()["websocket"].to_string ();
        return QUrl (websocket);
    }
    
    bool Capabilities.chunking_parallel_upload_disabled () {
        return _capabilities["dav"].to_map ()["chunking_parallel_upload_disabled"].to_bool ();
    }
    
    bool Capabilities.private_link_property_available () {
        return _capabilities["files"].to_map ()["private_links"].to_bool ();
    }
    
    QList<int> Capabilities.http_error_codes_that_reset_failing_chunked_uploads () {
        QList<int> list;
        foreach (auto &t, _capabilities["dav"].to_map ()["http_error_codes_that_reset_failing_chunked_uploads"].to_list ()) {
            list.push_back (t.to_int ());
        }
        return list;
    }
    
    string Capabilities.invalid_filename_regex () {
        return _capabilities[QStringLiteral ("dav")].to_map ()[QStringLiteral ("invalid_filename_regex")].to_string ();
    }
    
    bool Capabilities.upload_conflict_files () {
        static auto env_is_set = !q_environment_variable_is_empty ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        static int env_value = q_environment_variable_int_value ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        if (env_is_set)
            return env_value != 0;
    
        return _capabilities[QStringLiteral ("upload_conflict_files")].to_bool ();
    }
    
    QStringList Capabilities.blacklisted_files () {
        return _capabilities["files"].to_map ()["blacklisted_files"].to_string_list ();
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    // Direct Editing
    void Capabilities.add_direct_editor (Direct_editor* direct_editor) {
        if (direct_editor)
            _direct_editors.append (direct_editor);
    }
    
    Direct_editor* Capabilities.get_direct_editor_for_mimetype (QMime_type &mime_type) {
        foreach (Direct_editor* editor, _direct_editors) {
            if (editor.has_mimetype (mime_type))
                return editor;
        }
    
        return nullptr;
    }
    
    Direct_editor* Capabilities.get_direct_editor_for_optional_mimetype (QMime_type &mime_type) {
        foreach (Direct_editor* editor, _direct_editors) {
            if (editor.has_optional_mimetype (mime_type))
                return editor;
        }
    
        return nullptr;
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    Direct_editor.Direct_editor (string &id, string &name, GLib.Object* parent)
        : GLib.Object (parent)
        , _id (id)
        , _name (name) {
    }
    
    string Direct_editor.id () {
        return _id;
    }
    
    string Direct_editor.name () {
        return _name;
    }
    
    void Direct_editor.add_mimetype (QByteArray &mime_type) {
        _mime_types.append (mime_type);
    }
    
    void Direct_editor.add_optional_mimetype (QByteArray &mime_type) {
        _optional_mime_types.append (mime_type);
    }
    
    QList<QByteArray> Direct_editor.mime_types () {
        return _mime_types;
    }
    
    QList<QByteArray> Direct_editor.optional_mime_types () {
        return _optional_mime_types;
    }
    
    bool Direct_editor.has_mimetype (QMime_type &mime_type) {
        return _mime_types.contains (mime_type.name ().to_latin1 ());
    }
    
    bool Direct_editor.has_optional_mimetype (QMime_type &mime_type) {
        return _optional_mime_types.contains (mime_type.name ().to_latin1 ());
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    }
    