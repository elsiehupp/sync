/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <qglobal.h>
//  #include <QTemporaryDir>

namespace Occ {
namespace Testing {

public class TestAccount : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_test_account_dav_path_unitialized_no_crash () {
        unowned Account account = Account.create ();
        account.dav_path;
    }

} // namespace Testing
} // class TestAccount
