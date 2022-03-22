namespace Occ {
namespace Common {

/***********************************************************
@class SyncJournalErrorBlocklistRecord

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class SyncJournalErrorBlocklistRecord : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Category {
        /***********************************************************
        NORMAL errors have no special behavior
        ***********************************************************/
        NORMAL = 0,

        /***********************************************************
        These get a special summary message
        ***********************************************************/
        INSUFFICIENT_REMOTE_STORAGE
    }


    /***********************************************************
    The number of times the operation was unsuccessful so far.
    ***********************************************************/
    public int retry_count = 0;


    /***********************************************************
    The last error string.
    ***********************************************************/
    public string error_string;

    /***********************************************************
    The error category. Sometimes used for special actions.
    ***********************************************************/
    public Category error_category = Category.NORMAL;


    /***********************************************************
    ***********************************************************/
    public int64 last_try_modtime = 0;


    /***********************************************************
    ***********************************************************/
    public string last_try_etag;


    /***********************************************************
    The last time the operation was attempted (in s since epoch).
    ***********************************************************/
    public int64 last_try_time = 0;


    /***********************************************************
    The number of seconds the file shall be ignored.
    ***********************************************************/
    public int64 ignore_duration = 0;

    /***********************************************************
    ***********************************************************/
    public string file;


    /***********************************************************
    ***********************************************************/
    public string rename_target;


    /***********************************************************
    The last X-Request-ID of the request that failled
    ***********************************************************/
    public string request_id;

    /***********************************************************
    ***********************************************************/
    public bool is_valid ();

} // class SyncJournalErrorBlocklistRecord

} // namespace Common
} // namespace Occ
