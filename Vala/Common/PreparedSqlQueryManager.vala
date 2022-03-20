/***********************************************************
@author Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using Sqlite3;

namespace Occ {

/***********************************************************
@brief Manage PreparedSqlQuery
***********************************************************/
public class PreparedSqlQueryManager {

    /***********************************************************
    ***********************************************************/
    private SqlQuery queries[Key.PREPARED_QUERY_COUNT];
    //  private Q_DISABLE_COPY (PreparedSqlQueryManager)

    /***********************************************************
    ***********************************************************/
    public enum Key {
        GET_FILE_RECORD_QUERY,
        GET_FILE_RECORD_QUERY_BY_MANGLED_NAME,
        GET_FILE_RECORD_QUERY_BY_INODE,
        GET_FILE_RECORD_QUERY_BY_FILE_ID,
        GET_FILES_BELOW_PATH_QUERY,
        GET_ALL_FILES_QUERY,
        LIST_FILES_IN_PATH_QUERY,
        SET_FILE_RECORD_QUERY,
        SET_FILE_RECORD_CHECKSUM_QUERY,
        SET_FILE_LOCAL_METADATA_QUERY,
        GET_DOWNLOAD_INFO_QUERY,
        SET_DOWNLOAD_INFO_QUERY,
        DELETE_DOWNLOAD_INFO_QUERY,
        GET_UPLOAD_INFO_QUERY,
        SET_UPLOAD_INFO_QUERY,
        DELETE_UPLOAD_INFO_QUERY,
        DELETE_FILE_RECORD_PHASH,
        DELETE_FILE_RECORD_RECURSIVELY,
        GET_ERROR_BLOCKLIST_QUERY,
        SET_ERROR_BLOCKLIST_QUERY,
        GET_SELECTIVE_SYNC_LIST_QUERY,
        GET_CHECKSUM_TYPE_ID_QUERY,
        GET_CHECKSUM_TYPE_QUERY,
        INSERT_CHECKSUM_TYPE_QUERY,
        GET_DATA_FINGERPRINT_QUERY,
        SET_DATA_FINGERPRINT_QUERY1,
        SET_DATA_FINGERPRINT_QUERY2,
        SET_KEY_VALUE_STORE_QUERY,
        GET_KEY_VALUE_STORE_QUERY,
        DELETE_KEY_VALUE_STORE_QUERY,
        GET_CONFLICT_RECORD_QUERY,
        SET_CONFLICT_RECORD_QUERY,
        DELETE_CONFLICT_RECORD_QUERY,
        GET_RAW_PIN_STATE_QUERY,
        GET_EFFECTIVE_PIN_STATE_QUERY,
        GET_SUB_PINS_QUERY,
        COUNT_DEHYDRATED_FILES_QUERY,
        SET_PIN_STATE_QUERY,
        WIPE_PIN_STATE_QUERY,

        PREPARED_QUERY_COUNT
    }


    /***********************************************************
    The queries are reset in the destructor to prevent wal locks
    ***********************************************************/
    public PreparedSqlQuery get_for_key (Key key) {
        var query = this.queries[key];
        //  ENFORCE (query.stmt)
        //  Q_ASSERT (!Sqlite3StmtBusy (query.stmt));
        return new PreparedSqlQuery (
            query
        );
    }


    /***********************************************************
    Prepare the SqlQuery if it was not prepared yet.
    ***********************************************************/
    public PreparedSqlQuery get_for_key_sql_and_database (Key key, string sql, SqlDatabase database) {
        var query = this.queries[key];
        //  Q_ASSERT (!Sqlite3StmtBusy (query.stmt));
        //  ENFORCE (!query.sqldb || database == query.sqldb)
        if (!query.stmt) {
            query.sqldb = database;
            query.db = database.sqlite_db ();
            return new PreparedSqlQuery (
                query, query.prepare (sql) == 0
            );
        }
        return new PreparedSqlQuery (
            query
        );
    }

}

}
