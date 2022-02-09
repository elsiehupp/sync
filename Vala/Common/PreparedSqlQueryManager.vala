/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using Sqlite3;

namespace Occ {

/***********************************************************
@brief Manage PreparedSqlQuery
***********************************************************/
class PreparedSqlQueryManager {

    /***********************************************************
    ***********************************************************/
    public enum Key {
        Key.GET_FILE_RECORD_QUERY,
        Key.GET_FILE_RECORD_QUERY_BY_MANGLED_NAME,
        Key.GET_FILE_RECORD_QUERY_BY_INODE,
        Key.GET_FILE_RECORD_QUERY_BY_FILE_ID,
        Key.GET_FILES_BELOW_PATH_QUERY,
        Key.GET_ALL_FILES_QUERY,
        Key.LIST_FILES_IN_PATH_QUERY,
        Key.SET_FILE_RECORD_QUERY,
        Key.SET_FILE_RECORD_CHECKSUM_QUERY,
        Key.SET_FILE_LOCAL_METADATA_QUERY,
        Key.GET_DOWNLOAD_INFO_QUERY,
        Key.SET_DOWNLOAD_INFO_QUERY,
        Key.DELETE_DOWNLOAD_INFO_QUERY,
        Key.GET_UPLOAD_INFO_QUERY,
        Key.SET_UPLOAD_INFO_QUERY,
        Key.DELETE_UPLOAD_INFO_QUERY,
        Key.DELETE_FILE_RECORD_PHASH,
        Key.DELETE_FILE_RECORD_RECURSIVELY,
        GetErrorBlocklistQuery,
        SetErrorBlocklistQuery,
        Get_selective_sync_list_query,
        Get_checksum_type_id_query,
        Get_checksum_type_query,
        Insert_checksum_type_query,
        Get_data_fingerprint_query,
        Set_data_fingerprint_query1,
        Set_data_fingerprint_query2,
        SetKeyValueStoreQuery,
        GetKeyValueStoreQuery,
        DeleteKeyValueStoreQuery,
        Get_conflict_record_query,
        Set_conflict_record_query,
        Delete_conflict_record_query,
        Get_raw_pin_state_query,
        Get_effective_pin_state_query,
        Get_sub_pins_query,
        Count_dehydrated_files_query,
        Set_pin_state_query,
        Wipe_pin_state_query,

        Prepared_query_count
    }


    /***********************************************************
    ***********************************************************/
    public PreparedSqlQueryManager () = default;


    /***********************************************************
    The queries are reset in the destructor to prevent wal locks
    ***********************************************************/
    public const PreparedSqlQuery get (Key key) {
        var query = this.queries[key];
        ENFORCE (query.stmt)
        //  Q_ASSERT (!Sqlite3Stmt_busy (query.stmt));
        return {
            query
        }
    }


    /***********************************************************
    Prepare the SqlQuery if it was not prepared yet.
    ***********************************************************/
    public const PreparedSqlQuery get (Key key, GLib.ByteArray sql, SqlDatabase database) {
        var query = this.queries[key];
        //  Q_ASSERT (!Sqlite3Stmt_busy (query.stmt));
        ENFORCE (!query.sqldb || database == query.sqldb)
        if (!query.stmt) {
            query.sqldb = database;
            query.db = database.sqlite_db ();
            return {
                query, query.prepare (sql) == 0
            }
        }
        return {
            query
        }
    }


    /***********************************************************
    ***********************************************************/
    private SqlQuery this.queries[Prepared_query_count];
    private Q_DISABLE_COPY (PreparedSqlQueryManager)
}

}