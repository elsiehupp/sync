namespace Occ {
namespace Common {

/***********************************************************
@class PreparedSqlQuery

@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class PreparedSqlQuery : GLib.Object {

    using Sqlite3;

    /***********************************************************
    ***********************************************************/
    private SqlQuery query;

    /***********************************************************
    ***********************************************************/
    private bool ok;

    /***********************************************************
    ***********************************************************/
    private PreparedSqlQuery (SqlQuery query, bool ok = true) {
        this.query = query;
        this.ok = ok;
    }

    ~PreparedSqlQuery () {
        this.query.reset_and_clear_bindings ();
    }


    /***********************************************************
    ***********************************************************/
    public bool to_bool () {
        return this.ok;
    }

    //  public SqlQuery operator. () {
    //      //  Q_ASSERT (this.ok);
    //      return this.query;
    //  }

    //  public SqlQuery operator* () & {
    //      //  Q_ASSERT (this.ok);
    //      return this.query;
    //  }

} // class PreparedSqlQuery

} // namespace Common
} // namespace Occ
