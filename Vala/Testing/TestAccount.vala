/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <qglobal.h>
//  #include <QTemporaryDir>
//  #include <QtTest>

using Occ;

namespace Testing {

class TestAccount : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_test_account_dav_path_unitialized_no_crash () {
        AccountPointer account = Account.create ();
        account.davPath ();
    }

} // namespace Testing
} // class TestAccount
