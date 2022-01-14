/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class Prepared_sqlQuery {

    public ~Prepared_sqlQuery ();

    public operator bool () { return _ok; }

    public SqlQuery *operator. () {
        Q_ASSERT (_ok);
        return _query;
    }

    public SqlQuery &operator* () const & {
        Q_ASSERT (_ok);
        return *_query;
    }

private:
    Prepared_sqlQuery (SqlQuery *query, bool ok = true);

    SqlQuery *_query;
    bool _ok;

    friend class PreparedSqlQueryManager;
};

/***********************************************************
@brief Manage Prepared_sqlQuery
***********************************************************/
class PreparedSqlQueryManager {

    public enum Key {
        Key.GET_FILE_RECORD_QUERY,
        Key.GET_FILE_RECORD_QUERY_BY_MANGLED_NAME,
        Key.GET_FILE_RECORD_QUERY_BY_INODE,
        Key.GET_FILE_RECORD_QUERY_BY_FILE_ID,
        GetFilesBelowPathQuery,
        GetAllFilesQuery,
        List_files_in_path_query,
        SetFileRecordQuery,
        Set_file_record_checksum_query,
        Set_file_record_local_metadata_query,
        Get_download_info_query,
        Set_download_info_query,
        DeleteDownloadInfoQuery,
        Get_upload_info_query,
        Set_upload_info_query,
        DeleteUploadInfoQuery,
        DeleteFileRecordPhash,
        DeleteFileRecordRecursively,
        GetErrorBlacklistQuery,
        Set_error_blacklist_query,
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
    };
    public PreparedSqlQueryManager () = default;
    /***********************************************************
    The queries are reset in the destructor to prevent wal locks
    ***********************************************************/
    public const Prepared_sqlQuery get (Key key);
    /***********************************************************
    Prepare the SqlQuery if it was not prepared yet.
    ***********************************************************/
    public const Prepared_sqlQuery get (Key key, QByteArray &sql, SqlDatabase &db);

private:
    SqlQuery _queries[Prepared_query_count];
    Q_DISABLE_COPY (PreparedSqlQueryManager)
};

}


/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <Sqlite3.h>

using namespace Occ;

Prepared_sqlQuery.Prepared_sqlQuery (SqlQuery *query, bool ok)
    : _query (query)
    , _ok (ok) {
}

Prepared_sqlQuery.~Prepared_sqlQuery () {
    _query.reset_and_clear_bindings ();
}

const Prepared_sqlQuery PreparedSqlQueryManager.get (PreparedSqlQueryManager.Key key) {
    auto &query = _queries[key];
    ENFORCE (query._stmt)
    Q_ASSERT (!sqlite3_stmt_busy (query._stmt));
    return { &query };
}

const Prepared_sqlQuery PreparedSqlQueryManager.get (PreparedSqlQueryManager.Key key, QByteArray &sql, SqlDatabase &db) {
    auto &query = _queries[key];
    Q_ASSERT (!sqlite3_stmt_busy (query._stmt));
    ENFORCE (!query._sqldb || &db == query._sqldb)
    if (!query._stmt) {
        query._sqldb = &db;
        query._db = db.sqlite_db ();
        return { &query, query.prepare (sql) == 0 };
    }
    return { &query };
}
