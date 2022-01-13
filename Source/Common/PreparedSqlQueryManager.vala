/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class PreparedSqlQuery {

    public ~PreparedSqlQuery ();

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
    PreparedSqlQuery (SqlQuery *query, bool ok = true);

    SqlQuery *_query;
    bool _ok;

    friend class PreparedSqlQueryManager;
};

/***********************************************************
@brief Manage PreparedSqlQuery
***********************************************************/
class PreparedSqlQueryManager {

    public enum Key {
        GetFileRecordQuery,
        GetFileRecordQueryByMangledName,
        GetFileRecordQueryByInode,
        GetFileRecordQueryByFileId,
        GetFilesBelowPathQuery,
        GetAllFilesQuery,
        ListFilesInPathQuery,
        SetFileRecordQuery,
        SetFileRecordChecksumQuery,
        SetFileRecordLocalMetadataQuery,
        GetDownloadInfoQuery,
        SetDownloadInfoQuery,
        DeleteDownloadInfoQuery,
        GetUploadInfoQuery,
        SetUploadInfoQuery,
        DeleteUploadInfoQuery,
        DeleteFileRecordPhash,
        DeleteFileRecordRecursively,
        GetErrorBlacklistQuery,
        SetErrorBlacklistQuery,
        GetSelectiveSyncListQuery,
        GetChecksumTypeIdQuery,
        GetChecksumTypeQuery,
        InsertChecksumTypeQuery,
        GetDataFingerprintQuery,
        SetDataFingerprintQuery1,
        SetDataFingerprintQuery2,
        SetKeyValueStoreQuery,
        GetKeyValueStoreQuery,
        DeleteKeyValueStoreQuery,
        GetConflictRecordQuery,
        SetConflictRecordQuery,
        DeleteConflictRecordQuery,
        GetRawPinStateQuery,
        GetEffectivePinStateQuery,
        GetSubPinsQuery,
        CountDehydratedFilesQuery,
        SetPinStateQuery,
        WipePinStateQuery,

        PreparedQueryCount
    };
    public PreparedSqlQueryManager () = default;
    /***********************************************************
    The queries are reset in the destructor to prevent wal locks
    ***********************************************************/
    public const PreparedSqlQuery get (Key key);
    /***********************************************************
    Prepare the SqlQuery if it was not prepared yet.
    ***********************************************************/
    public const PreparedSqlQuery get (Key key, QByteArray &sql, SqlDatabase &db);

private:
    SqlQuery _queries[PreparedQueryCount];
    Q_DISABLE_COPY (PreparedSqlQueryManager)
};

}


/***********************************************************
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <Sqlite3.h>

using namespace Occ;

PreparedSqlQuery.PreparedSqlQuery (SqlQuery *query, bool ok)
    : _query (query)
    , _ok (ok) {
}

PreparedSqlQuery.~PreparedSqlQuery () {
    _query.reset_and_clear_bindings ();
}

const PreparedSqlQuery PreparedSqlQueryManager.get (PreparedSqlQueryManager.Key key) {
    auto &query = _queries[key];
    ENFORCE (query._stmt)
    Q_ASSERT (!sqlite3_stmt_busy (query._stmt));
    return { &query };
}

const PreparedSqlQuery PreparedSqlQueryManager.get (PreparedSqlQueryManager.Key key, QByteArray &sql, SqlDatabase &db) {
    auto &query = _queries[key];
    Q_ASSERT (!sqlite3_stmt_busy (query._stmt));
    ENFORCE (!query._sqldb || &db == query._sqldb)
    if (!query._stmt) {
        query._sqldb = &db;
        query._db = db.sqliteDb ();
        return { &query, query.prepare (sql) == 0 };
    }
    return { &query };
}
