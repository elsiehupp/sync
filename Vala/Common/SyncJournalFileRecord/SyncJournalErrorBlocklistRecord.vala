/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/


namespace Occ {

class SyncJournalErrorBlocklistRecord {

    /***********************************************************
    ***********************************************************/
    public enum Category {
        /***********************************************************
        Normal errors have no special behavior
        ***********************************************************/
        Normal = 0,

        /***********************************************************
        These get a special summary message
        ***********************************************************/
        InsufficientRemoteStorage
    };


    /***********************************************************
    The number of times the operation was unsuccessful so far.
    ***********************************************************/
    public int this.retry_count = 0;


    /***********************************************************
    The last error string.
    ***********************************************************/
    public string this.error_string;


    /***********************************************************
    The error category. Sometimes used for special actions.
    ***********************************************************/
    public Category this.error_category = Category.Normal;

    /***********************************************************
    ***********************************************************/
    public int64 this.last_try_modtime = 0;


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray this.last_try_etag;


    /***********************************************************
    The last time the operation was attempted (in s since epoch).
    ***********************************************************/
    public int64 this.last_try_time = 0;


    /***********************************************************
    The number of seconds the file shall be ignored.
    ***********************************************************/
    public int64 this.ignore_duration = 0;

    /***********************************************************
    ***********************************************************/
    public string this.file;


    /***********************************************************
    ***********************************************************/
    public string this.rename_target;


    /***********************************************************
    The last X-Request-ID of the request that failled
    ***********************************************************/
    public GLib.ByteArray this.request_id;

    /***********************************************************
    ***********************************************************/
    public bool is_valid ();
}
