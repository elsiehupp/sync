/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariantMap>
// #include <QLoggingCategory>
// #include <QUrl>

// #include <QDebug>

// #include <QVariantMap>
// #include <string[]>
// #include <QMimeDatabase>

namespace Occ {


enum PushNotificationType {
    None = 0,
    Files = 1,
    Activities = 2,
    Notifications = 4
};
Q_DECLARE_FLAGS (PushNotificationTypes, PushNotificationType)
Q_DECLARE_OPERATORS_FOR_FLAGS (PushNotificationTypes)

/***********************************************************
@brief The Capabilities class represents the capabilities of an own_cloud
server
@ingroup libsync
***********************************************************/
class Capabilities {

    public Capabilities (QVariantMap &capabilities);

    public bool share_a_p_i ();


    public bool share_email_password_enabled ();


    public bool share_email_password_enforced ();


    public bool share_public_link ();


    public bool share_public_link_allow_upload ();


    public bool share_public_link_supports_upload_only ();


    public bool share_public_link_ask_optional_password ();


    public bool share_public_link_enforce_password ();


    public bool share_public_link_enforce_expire_date ();


    public int share_public_link_expire_date_days ();


    public bool share_internal_enforce_expire_date ();


    public int share_internal_expire_date_days ();


    public bool share_remote_enforce_expire_date ();


    public int share_remote_expire_date_days ();


    public bool share_public_link_multiple ();


    public bool share_resharing ();


    public int share_default_permissions ();


    public bool chunking_ng ();


    public bool bulk_upload ();


    public bool user_status ();


    public bool user_status_supports_emoji ();

    /// Returns which kind of push notfications are available
    public PushNotificationTypes available_push_notifications ();

    /// Websocket url for files push notifications if available
    public QUrl push_notifications_web_socket_url ();

    /// disable parallel upload in chunking
    public bool chunking_parallel_upload_disabled ();

    /// Whether the "privatelink" DAV property is available
    public bool private_link_property_available ();

    /// returns true if the capabilities report notifications
    public bool notifications_available ();

    /// returns true if the server supports client side encryption
    public bool client_side_encryption_available ();

    /// returns true if the capabilities are loaded already.
    public bool is_valid ();

    /// return true if the activity app is enabled
    public bool has_activities ();


    /***********************************************************
    Returns the checksum types the server understands.

    When the client uses one of these checksumming algorithms in
    the OC-Checksum header of a file upload, the server
    it to validate that data was tr

    Path : checksums/supported_types
    Default: []
    Possible entries : "Adler32", "MD5", "SHA1"
    ***********************************************************/
    public GLib.List<GLib.ByteArray> supported_checksum_types ();


    /***********************************************************
    The checksum algorithm that the server recommends for file uploads.
    This is just a preference, any algorithm listed in supported_types may be used.

    Path : checksums/preferred_upload_type
    Default: empty, meaning "no preference"
    Possible values : empty or any of the supported_types
    ***********************************************************/
    public GLib.ByteArray preferred_upload_checksum_type ();


    /***********************************************************
    Helper that returns the preferred_upload_checksum_type () if set, or one
    of the supported_checksum_types () if it isn't. May return an empty
    GLib.ByteArray if no checksum types are supported.
    ***********************************************************/
    public GLib.ByteArray upload_checksum_type ();


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
    Default: []
    Example: [503, 500]
    ***********************************************************/
    public GLib.List<int> http_error_codes_that_reset_failing_chunked_uploads ();


    /***********************************************************
    Regex that, if contained in a filename, will result in it not being uploaded.

    For servers older than 8.1.0 it defaults to [\\:?*"<>|]
    For servers >= that version, it defaults to the empty rege
    will indicate invalid characters through an upload error)

    Note that it just needs to be contained. The regex [ab] is contained in "car".
    ***********************************************************/
    public string invalid_filename_regex ();


    /***********************************************************
    return the list of filename that should not be uploaded
    ***********************************************************/
    public string[] blacklisted_files ();


    /***********************************************************
    Whether conflict files should remain local (default) or should be uploaded.
    ***********************************************************/
    public bool upload_conflict_files ();

    // Direct Editing
    public void add_direct_editor (DirectEditor* direct_editor);


    public DirectEditor* get_direct_editor_for_mimetype (QMimeType &mime_type);


    public DirectEditor* get_direct_editor_for_optional_mimetype (QMimeType &mime_type);


    private QVariantMap _capabilities;

    private GLib.List<DirectEditor> _direct_editors;
};

/*-------------------------------------------------------------------------------------*/

class DirectEditor : GLib.Object {

    public DirectEditor (string id, string name, GLib.Object* parent = nullptr);

    public void add_mimetype (GLib.ByteArray mime_type);


    public void add_optional_mimetype (GLib.ByteArray mime_type);

    public bool has_mimetype (QMimeType &mime_type);


    public bool has_optional_mimetype (QMimeType &mime_type);

    public string id ();


    public string name ();

    public GLib.List<GLib.ByteArray> mime_types ();


    public GLib.List<GLib.ByteArray> optional_mime_types ();


    private string _id;
    private string _name;

    private GLib.List<GLib.ByteArray> _mime_types;
    private GLib.List<GLib.ByteArray> _optional_mime_types;
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
        var it = _capabilities.const_find (QStringLiteral ("end-to-end-encryption"));
        if (it == _capabilities.const_end ()) {
            return false;
        }

        const var properties = (*it).to_map ();
        const var enabled = properties.value (QStringLiteral ("enabled"), false).to_bool ();
        if (!enabled) {
            return false;
        }

        const var version = properties.value (QStringLiteral ("api-version"), "1.0").to_byte_array ();
        q_c_info (lc_server_capabilities) << "E2EE API version:" << version;
        const var splitted_version = version.split ('.');

        bool ok = false;
        const var major = !splitted_version.is_empty () ? splitted_version.at (0).to_int (&ok) : 0;
        if (!ok) {
            q_c_warning (lc_server_capabilities) << "Didn't understand version scheme (major), E2EE disabled";
            return false;
        }

        ok = false;
        const var minor = splitted_version.size () > 1 ? splitted_version.at (1).to_int (&ok) : 0;
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

    GLib.List<GLib.ByteArray> Capabilities.supported_checksum_types () {
        GLib.List<GLib.ByteArray> list;
        foreach (var &t, _capabilities["checksums"].to_map ()["supported_types"].to_list ()) {
            list.push_back (t.to_byte_array ());
        }
        return list;
    }

    GLib.ByteArray Capabilities.preferred_upload_checksum_type () {
        return q_environment_variable ("OWNCLOUD_CONTENT_CHECKSUM_TYPE",
                                    _capabilities.value (QStringLiteral ("checksums")).to_map ()
                                    .value (QStringLiteral ("preferred_upload_type"), QStringLiteral ("SHA1")).to_string ()).to_utf8 ();
    }

    GLib.ByteArray Capabilities.upload_checksum_type () {
        GLib.ByteArray preferred = preferred_upload_checksum_type ();
        if (!preferred.is_empty ())
            return preferred;
        GLib.List<GLib.ByteArray> supported = supported_checksum_types ();
        if (!supported.is_empty ())
            return supported.first ();
        return GLib.ByteArray ();
    }

    bool Capabilities.chunking_ng () {
        static const var chunkng = qgetenv ("OWNCLOUD_CHUNKING_NG");
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
        const var user_status_map = _capabilities["user_status"].to_map ();
        return user_status_map.value ("enabled", false).to_bool ();
    }

    bool Capabilities.user_status_supports_emoji () {
        if (!user_status ()) {
            return false;
        }
        const var user_status_map = _capabilities["user_status"].to_map ();
        return user_status_map.value ("supports_emoji", false).to_bool ();
    }

    PushNotificationTypes Capabilities.available_push_notifications () {
        if (!_capabilities.contains ("notify_push")) {
            return PushNotificationType.None;
        }

        const var types = _capabilities["notify_push"].to_map ()["type"].to_string_list ();
        PushNotificationTypes push_notification_types;

        if (types.contains ("files")) {
            push_notification_types.set_flag (PushNotificationType.Files);
        }

        if (types.contains ("activities")) {
            push_notification_types.set_flag (PushNotificationType.Activities);
        }

        if (types.contains ("notifications")) {
            push_notification_types.set_flag (PushNotificationType.Notifications);
        }

        return push_notification_types;
    }

    QUrl Capabilities.push_notifications_web_socket_url () {
        const var websocket = _capabilities["notify_push"].to_map ()["endpoints"].to_map ()["websocket"].to_string ();
        return QUrl (websocket);
    }

    bool Capabilities.chunking_parallel_upload_disabled () {
        return _capabilities["dav"].to_map ()["chunking_parallel_upload_disabled"].to_bool ();
    }

    bool Capabilities.private_link_property_available () {
        return _capabilities["files"].to_map ()["private_links"].to_bool ();
    }

    GLib.List<int> Capabilities.http_error_codes_that_reset_failing_chunked_uploads () {
        GLib.List<int> list;
        foreach (var &t, _capabilities["dav"].to_map ()["http_error_codes_that_reset_failing_chunked_uploads"].to_list ()) {
            list.push_back (t.to_int ());
        }
        return list;
    }

    string Capabilities.invalid_filename_regex () {
        return _capabilities[QStringLiteral ("dav")].to_map ()[QStringLiteral ("invalid_filename_regex")].to_string ();
    }

    bool Capabilities.upload_conflict_files () {
        static var env_is_set = !q_environment_variable_is_empty ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        static int env_value = q_environment_variable_int_value ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        if (env_is_set)
            return env_value != 0;

        return _capabilities[QStringLiteral ("upload_conflict_files")].to_bool ();
    }

    string[] Capabilities.blacklisted_files () {
        return _capabilities["files"].to_map ()["blacklisted_files"].to_string_list ();
    }

    /*-------------------------------------------------------------------------------------*/

    // Direct Editing
    void Capabilities.add_direct_editor (DirectEditor* direct_editor) {
        if (direct_editor)
            _direct_editors.append (direct_editor);
    }

    DirectEditor* Capabilities.get_direct_editor_for_mimetype (QMimeType &mime_type) {
        foreach (DirectEditor* editor, _direct_editors) {
            if (editor.has_mimetype (mime_type))
                return editor;
        }

        return nullptr;
    }

    DirectEditor* Capabilities.get_direct_editor_for_optional_mimetype (QMimeType &mime_type) {
        foreach (DirectEditor* editor, _direct_editors) {
            if (editor.has_optional_mimetype (mime_type))
                return editor;
        }

        return nullptr;
    }

    /*-------------------------------------------------------------------------------------*/

    DirectEditor.DirectEditor (string id, string name, GLib.Object* parent)
        : GLib.Object (parent)
        , _id (id)
        , _name (name) {
    }

    string DirectEditor.id () {
        return _id;
    }

    string DirectEditor.name () {
        return _name;
    }

    void DirectEditor.add_mimetype (GLib.ByteArray mime_type) {
        _mime_types.append (mime_type);
    }

    void DirectEditor.add_optional_mimetype (GLib.ByteArray mime_type) {
        _optional_mime_types.append (mime_type);
    }

    GLib.List<GLib.ByteArray> DirectEditor.mime_types () {
        return _mime_types;
    }

    GLib.List<GLib.ByteArray> DirectEditor.optional_mime_types () {
        return _optional_mime_types;
    }

    bool DirectEditor.has_mimetype (QMimeType &mime_type) {
        return _mime_types.contains (mime_type.name ().to_latin1 ());
    }

    bool DirectEditor.has_optional_mimetype (QMimeType &mime_type) {
        return _optional_mime_types.contains (mime_type.name ().to_latin1 ());
    }

    /*-------------------------------------------------------------------------------------*/

    }
    