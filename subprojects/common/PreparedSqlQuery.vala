namespace Occ {
namespace Common {

/***********************************************************
@class PreparedSqlQuery

@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class PreparedSqlQuery { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private SqlQuery query;

    /***********************************************************
    ***********************************************************/
    private bool ok;

    /***********************************************************
    ***********************************************************/
    internal PreparedSqlQuery (SqlQuery query, bool ok = true) {
        //      this.query = query;
        //      this.ok = ok;
    }

    ~PreparedSqlQuery () {
        //      this.query.reset_and_clear_bindings ();
    }


    /***********************************************************
    ***********************************************************/
    public bool to_bool () {
        //      return this.ok;
    }

} // class PreparedSqlQuery

} // namespace Common
} // namespace Occ
