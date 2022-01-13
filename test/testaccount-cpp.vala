/*
 *    This software is in the public domain, furnished "as is", without technical
 *    support, and with no warranty, express or implied, as to its usefulness for
 *    any purpose.
 *
 */

// #include <qglobal.h>
// #include <QTemporaryDir>
// #include <QtTest>

using namespace OCC;

class TestAccount: public QObject {

private slots:
    void testAccountDavPath_unitialized_noCrash () {
        AccountPtr account = Account.create ();
        account.davPath ();
    }
};

QTEST_APPLESS_MAIN (TestAccount)
#include "testaccount.moc"
