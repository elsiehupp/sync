/***********************************************************
***********************************************************/

//  #include <GLib.HashTable<string, GLib.Variant>>
//  #include <QDebug>
//  #include <GLib.HashTable<string, GLib.Variant>>
//  #include <QMimeDatabase>

namespace Occ {
namespace LibSync {

/***********************************************************
@class Capabilities

@brief The Capabilities class represents the capabilities of
an OCS server

@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/
public class Capabilities : GLib.Object {

    public enum PushNotificationType {
        NONE = 0,
        FILES = 1,
        ACTIVITIES = 2,
        NOTIFICATIONS = 4
    }


    /***********************************************************
    ***********************************************************/
    private GLib.HashTable<string, GLib.Variant> capabilities;

    /***********************************************************
    ***********************************************************/
    private GLib.List<DirectEditor> direct_editors;

    /***********************************************************
    ***********************************************************/
    public Capabilities (GLib.HashTable<string, GLib.Variant> capabilities) {
        this.capabilities = capabilities;
    }


    /***********************************************************
    ***********************************************************/
    public bool share_api () {
        if (this.capabilities["files_sharing"].to_map ().contains ("api_enabled")) {
            return this.capabilities["files_sharing"].to_map ()["api_enabled"].to_bool ();
        } else {
            // This was later added so if it is not present just assume the API is enabled.
            return true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool share_email_password_enabled () {
        return this.capabilities["files_sharing"].to_map ()["sharebymail"].to_map ()["password"].to_map ()["enabled"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_email_password_enforced () {
        return this.capabilities["files_sharing"].to_map ()["sharebymail"].to_map ()["password"].to_map ()["enforced"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link () {
        if (this.capabilities["files_sharing"].to_map ().contains ("public")) {
            return share_api () && this.capabilities["files_sharing"].to_map ()["public"].to_map ()["enabled"].to_bool ();
        } else {
            // This was later added so if it is not present just assume that link sharing is enabled.
            return true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_allow_upload () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["upload"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_ask_optional_password () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["password"].to_map ()["ask_for_optional_password"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_supports_upload_only () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["supports_upload_only"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_enforce_password () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["password"].to_map ()["enforced"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_enforce_expire_date () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date"].to_map ()["enforced"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public int share_public_link_expire_date_days () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date"].to_map ()["days"].to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_internal_enforce_expire_date () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_internal"].to_map ()["enforced"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public int share_internal_expire_date_days () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_internal"].to_map ()["days"].to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_remote_enforce_expire_date () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_remote"].to_map ()["enforced"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public int share_remote_expire_date_days () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["expire_date_remote"].to_map ()["days"].to_int ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_public_link_multiple () {
        return this.capabilities["files_sharing"].to_map ()["public"].to_map ()["multiple"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool share_resharing () {
        return this.capabilities["files_sharing"].to_map ()["resharing"].to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public int share_default_permissions () {
        if (this.capabilities["files_sharing"].to_map ().contains ("default_permissions")) {
            return this.capabilities["files_sharing"].to_map ()["default_permissions"].to_int ();
        }

        return {};
    }


    /***********************************************************
    ***********************************************************/
    public bool chunking_ng () {
        var chunkng = qgetenv ("OWNCLOUD_CHUNKING_NG");
        if (chunkng == "0")
            return false;
        if (chunkng == "1")
            return true;
        return this.capabilities["dav"].to_map ()["chunking"].to_byte_array () >= "1.0";
    }


    /***********************************************************
    ***********************************************************/
    public bool bulk_upload () {
        return this.capabilities["dav"].to_map ()["bulkupload"].to_byte_array () >= "1.0";
    }


    /***********************************************************
    ***********************************************************/
    public bool user_status () {
        if (!this.capabilities.contains ("user_status")) {
            return false;
        }
        var user_status_map = this.capabilities["user_status"].to_map ();
        return user_status_map.value ("enabled", false).to_bool ();
    }


    /***********************************************************
    ***********************************************************/
    public bool user_status_supports_emoji () {
        if (!user_status ()) {
            return false;
        }
        var user_status_map = this.capabilities["user_status"].to_map ();
        return user_status_map.value ("supports_emoji", false).to_bool ();
    }


    /***********************************************************
    Returns which kind of push notfications are available
    ***********************************************************/
    public PushNotificationTypes available_push_notifications () {
        if (!this.capabilities.contains ("notify_push")) {
            return PushNotificationType.NONE;
        }

        var types = this.capabilities["notify_push"].to_map ()["type"].to_string_list ();
        PushNotificationTypes push_notification_types;

        if (types.contains ("files")) {
            push_notification_types.flag (PushNotificationType.FILES);
        }

        if (types.contains ("activities")) {
            push_notification_types.flag (PushNotificationType.ACTIVITIES);
        }

        if (types.contains ("notifications")) {
            push_notification_types.flag (PushNotificationType.NOTIFICATIONS);
        }

        return push_notification_types;
    }


    /***********************************************************
    Websocket url for files push notifications if available
    ***********************************************************/
    public GLib.Uri push_notifications_web_socket_url () {
        var websocket = this.capabilities["notify_push"].to_map ()["endpoints"].to_map ()["websocket"].to_string ();
        return GLib.Uri (websocket);
    }


    /***********************************************************
    Disable parallel upload in chunking
    ***********************************************************/
    public bool chunking_parallel_upload_disabled () {
        return this.capabilities["dav"].to_map ()["chunking_parallel_upload_disabled"].to_bool ();
    }


    /***********************************************************
    Whether the "privatelink" DAV property is available
    ***********************************************************/
    public bool private_link_property_available () {
        return this.capabilities["files"].to_map ()["private_links"].to_bool ();
    }


    /***********************************************************
    Returns true if the capabilities report notifications
    ***********************************************************/
    public bool notifications_available () {
        // We require the OCS style API in 9.x, can't deal with the REST one only found in 8.2
        return this.capabilities.contains ("notifications") && this.capabilities["notifications"].to_map ().contains ("ocs-endpoints");
    }


    /***********************************************************
    Returns true if the server supports client side encryption
    ***********************************************************/
    public bool client_side_encryption_available () {
        var it = this.capabilities.const_find ("end-to-end-encryption");
        if (it == this.capabilities.const_end ()) {
            return false;
        }

        var properties = (*it).to_map ();
        var enabled = properties.value ("enabled", false).to_bool ();
        if (!enabled) {
            return false;
        }

        var version = properties.value ("api-version", "1.0").to_byte_array ();
        GLib.info ("E2EE API version: " + version);
        var splitted_version = version.split ('.');

        bool ok = false;
        var major = !splitted_version == "" ? splitted_version.at (0).to_int (&ok) : 0;
        if (!ok) {
            GLib.warning ("Didn't understand version scheme (major), E2EE disabled.");
            return false;
        }

        ok = false;
        var minor = splitted_version.size () > 1 ? splitted_version.at (1).to_int (&ok) : 0;
        if (!ok) {
            GLib.warning ("Didn't understand version scheme (minor), E2EE disabled.");
            return false;
        }

        return major == 1 && minor >= 1;
    }


    /***********************************************************
    Returns true if the capabilities are loaded already.
    ***********************************************************/
    public bool is_valid () {
        return !this.capabilities == "";
    }


    /***********************************************************
    Returns true if the activity app is enabled.
    ***********************************************************/
    public bool has_activities () {
        return this.capabilities.contains ("activity");
    }


    /***********************************************************
    Returns the checksum types the server understands.

    When the client uses one of these checksumming algorithms in
    the OC-Checksum header of a file upload, the server
    it to validate that data was tr

    Path : checksums/supported_types
    Default: []
    Possible entries: "Adler32", "MD5", "SHA1"
    ***********************************************************/
    public GLib.List<string> supported_checksum_types () {
        GLib.List<string> list;
        foreach (var t in this.capabilities["checksums"].to_map ()["supported_types"].to_list ()) {
            list.push_back (t.to_byte_array ());
        }
        return list;
    }


    /***********************************************************
    The checksum algorithm that the server recommends for file uploads.
    This is just a preference, any algorithm listed in supported_types may be used.

    Path : checksums/preferred_upload_type
    Default: empty, meaning "no preference"
    Possible values : empty or any of the supported_types
    ***********************************************************/
    public string preferred_upload_checksum_type () {
        return q_environment_variable ("OWNCLOUD_CONTENT_CHECKSUM_TYPE",
            this.capabilities.value ("checksums").to_map ()
            .value ("preferred_upload_type", "SHA1").to_string ()).to_utf8 ();
    }


    /***********************************************************
    Helper that returns the preferred_upload_checksum_type () if
    set, or one of the supported_checksum_types () if it isn't.
    May return an empty string if no checksum types are
    supported.
    ***********************************************************/
    public string upload_checksum_type () {
        string preferred = preferred_upload_checksum_type ();
        if (!preferred == "") {
            return preferred;
        }
        GLib.List<string> supported = supported_checksum_types ();
        if (!supported == "") {
            return supported.first ();
        }
        return "";
    }


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
    public GLib.List<int> http_error_codes_that_reset_failing_chunked_uploads () {
        GLib.List<int> list;
        foreach (var t in this.capabilities["dav"].to_map ()["http_error_codes_that_reset_failing_chunked_uploads"].to_list ()) {
            list.push_back (t.to_int ());
        }
        return list;
    }


    /***********************************************************
    Regex that, if contained in a filename, will result in it not being uploaded.

    For servers older than 8.1.0 it defaults to [\\:?*"<>|]
    For servers >= that version, it defaults to the empty rege
    will indicate invalid characters through an upload error)

    Note that it just needs to be contained. The regular_expression [ab] is contained in "car".
    ***********************************************************/
    public string invalid_filename_regex () {
        return this.capabilities["dav"].to_map ()["invalid_filename_regex"].to_string ();
    }


    /***********************************************************
    return the list of filename that should not be uploaded
    ***********************************************************/
    public string[] blocklisted_files () {
        return this.capabilities["files"].to_map ()["blocklisted_files"].to_string_list ();
    }


    /***********************************************************
    Whether conflict files should remain local (default) or
    should be uploaded.
    ***********************************************************/
    public bool upload_conflict_files () {
        var env_is_set = !q_environment_variable_is_empty ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        int env_value = q_environment_variable_int_value ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        if (env_is_set)
            return env_value != 0;

        return this.capabilities["upload_conflict_files"].to_bool ();
    }


    /***********************************************************
    Direct Editing
    ***********************************************************/
    public void add_direct_editor (DirectEditor direct_editor) {
        if (direct_editor) {
            this.direct_editors.append (direct_editor);
        }
    }


    /***********************************************************
    ***********************************************************/
    public DirectEditor get_direct_editor_for_mimetype (QMimeType mime_type) {
        foreach (DirectEditor editor in this.direct_editors) {
            if (editor.has_mimetype (mime_type)) {
                return editor;
            }
        }

        return null;
    }


    /***********************************************************
    ***********************************************************/
    public DirectEditor get_direct_editor_for_optional_mimetype (QMimeType mime_type) {
        foreach (DirectEditor editor in this.direct_editors) {
            if (editor.has_optional_mimetype (mime_type))
                return editor;
        }

        return null;
    }

} // class Capabilities

} // namespace LibSync
} // namespace Occ
    