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

class TestRemoteWipe : GLib.Object {

    // TODO
    private void test_wipe () {
//        QTemporaryDir directory;
//        ConfigFile.setConfDir (directory.path ()); // we don't want to pollute the user's config file
//        //  QVERIFY (directory.isValid ());

//        QDir dirToRemove (directory.path ());
//        //  QVERIFY (dirToRemove.mkpath ("nextcloud"));

//        string directory_path = dirToRemove.canonicalPath ();

//        AccountPointer account = Account.create ();
//        //  QVERIFY (account);

//        var manager = AccountManager.instance ();
//        //  QVERIFY (manager);

//        AccountState new_account_state = manager.addAccount (account);
//        manager.save ();
//        //  QVERIFY (new_account_state);

//        GLib.Uri url ("http://example.de");
//        HttpCredentialsTest credentials = new HttpCredentialsTest ("testuser", "secret");
//        account.setCredentials (credentials);
//        account.set_url ( url );

//        FolderMan folder_manager = FolderMan.instance ();
//        folder_manager.addFolder (new_account_state, folder_definition (directory_path + "/sub/nextcloud/"));

//        // check if account exists
//        GLib.debug ("Does account exists?!";
//        //  QVERIFY (!account.identifier ().isEmpty ());

//        manager.deleteAccount (new_account_state);
//        manager.save ();

//        // check if account exists
//        GLib.debug ("Does account exists yet?!";
//        //  QVERIFY (account);

//        // check if folder exists
//        //  QVERIFY (dirToRemove.exists ());

//        // remote folders
//        GLib.debug () +  "Removing folder for account " + new_account_state.account ().url ();

//        folder_manager.slotWipeFolderForAccount (new_account_state);

//        // check if folders dont exist anymore
//        //  QCOMPARE (dirToRemove.exists (), false);
    }
}
}
