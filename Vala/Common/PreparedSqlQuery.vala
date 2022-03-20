/***********************************************************
@author Hannah von Reth <hannah.vonreth@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

using Sqlite3;

namespace Occ {

public class PreparedSqlQuery {

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
}

}
