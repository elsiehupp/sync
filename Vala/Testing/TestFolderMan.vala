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

class TestFolderMan : GLib.Object {

    FolderMan folder_manager;

    /***********************************************************
    ***********************************************************/
    private void testCheckPathValidityForNewFolder () {
        QTemporaryDir directory;
        ConfigFile.setConfDir (directory.path ()); // we don't want to pollute the user's config file
        //  QVERIFY (directory.isValid ());
        QDir dir2 = new QDir (directory.path ());
        //  QVERIFY (dir2.mkpath ("sub/ownCloud1/folder/file"));
        //  QVERIFY (dir2.mkpath ("ownCloud2"));
        //  QVERIFY (dir2.mkpath ("sub/free"));
        //  QVERIFY (dir2.mkpath ("free2/sub")); {
        //      GLib.File file = new GLib.File (directory.path () + "/sub/file.txt");
        //      file.open (GLib.File.WriteOnly);
        //      file.write ("hello");
        //  }
        string directory_path = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.setCredentials (credentials);
        account.set_url ( url );

        AccountStatePtr new_account_state = new AccountStatePtr (new AccountState (account));
        FolderMan folder_manager = FolderMan.instance ();
        //  QCOMPARE (folder_manager, this.folder_manager);
        //  QVERIFY (folder_manager.addFolder (new_account_state.data (), folder_definition (directory_path + "/sub/ownCloud1")));
        //  QVERIFY (folder_manager.addFolder (new_account_state.data (), folder_definition (directory_path + "/ownCloud2")));

        const var folder_list = folder_manager.map ();

        //  foreach (var folder in folder_list) {
        //      QVERIFY (!folder.isSyncRunning ());
        //  }

        // those should be allowed
        // string FolderMan.checkPathValidityForNewFolder (string path, GLib.Uri serverUrl, bool forNewDirectory)

        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/free"), "");
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/free2/"), "");
        // Not an existing directory . Ok
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/bliblablu"), "");
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/free/bliblablu"), "");
        // QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/bliblablu/some/more"), "");

        // A file . Error
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/file.txt").isNull ());

        // There are folders configured in those folders, url needs to be taken into account : . ERROR
        GLib.Uri url2 = new GLib.Uri (url);
        const string user = account.credentials ().user ();
        url2.set_user_name (user);

        // The following both fail because they refer to the same account (user and url)
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1", url2).isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/", url2).isNull ());

        // Now it will work because the account is different
        GLib.Uri url3 = new GLib.Uri ("http://anotherexample.org");
        url3.set_user_name ("dummy");
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1", url3), "");
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/", url3), "");

        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path).isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder/file").isNull ());

        // make a bunch of links
        //  QVERIFY (GLib.File.link (directory_path + "/sub/free", directory_path + "/link1"));
        //  QVERIFY (GLib.File.link (directory_path + "/sub", directory_path + "/link2"));
        //  QVERIFY (GLib.File.link (directory_path + "/sub/ownCloud1", directory_path + "/link3"));
        //  QVERIFY (GLib.File.link (directory_path + "/sub/ownCloud1/folder", directory_path + "/link4"));

        // Ok
        //  QVERIFY (folder_manager.checkPathValidityForNewFolder (directory_path + "/link1").isNull ());
        //  QVERIFY (folder_manager.checkPathValidityForNewFolder (directory_path + "/link2/free").isNull ());

        // Not Ok
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link2").isNull ());

        // link 3 points to an existing sync folder. To make it fail, the account must be the same
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3", url2).isNull ());
        // while with a different account, this is fine
        //  QCOMPARE (folder_manager.checkPathValidityForNewFolder (directory_path + "/link3", url3), "");

        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link4").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3/folder").isNull ());

        // test some non existing sub path (error)
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/some/sub/path").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/blublu").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder/g/h").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3/folder/neu_folder").isNull ());

        // Subfolder of links
        //  QVERIFY (folder_manager.checkPathValidityForNewFolder (directory_path + "/link1/subfolder").isNull ());
        //  QVERIFY (folder_manager.checkPathValidityForNewFolder (directory_path + "/link2/free/subfolder").isNull ());

        // Should not have the rights
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder ("/").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder ("/usr/bin/somefolder").isNull ());

        // Invalid paths
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder ("").isNull ());

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        QDir (directory_path + "/ownCloud2/").removeRecursively ();
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/blublu").isNull ());
        //  QVERIFY (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/sub/subsub/sub").isNull ());
    }


    /***********************************************************
    ***********************************************************/
    private void testFindGoodPathForNewSyncFolder () {
        // SETUP

        QTemporaryDir directory;
        ConfigFile.setConfDir (directory.path ()); // we don't want to pollute the user's config file
        //  QVERIFY (directory.isValid ());
        QDir dir2 = new QDir (directory.path ());
        //  QVERIFY (dir2.mkpath ("sub/ownCloud1/folder/file"));
        //  QVERIFY (dir2.mkpath ("ownCloud"));
        //  QVERIFY (dir2.mkpath ("ownCloud2"));
        //  QVERIFY (dir2.mkpath ("ownCloud2/foo"));
        //  QVERIFY (dir2.mkpath ("sub/free"));
        //  QVERIFY (dir2.mkpath ("free2/sub"));
        string directory_path = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.setCredentials (credentials);
        account.set_url (url);
        url.set_user_name (credentials.user ());

        AccountStatePtr new_account_state = new AccountStatePtr (new AccountState (account));
        FolderMan folder_manager = FolderMan.instance ();
        //  QCOMPARE (folder_manager, this.folder_manager);
        //  QVERIFY (folder_manager.addFolder (new_account_state.data (), folder_definition (directory_path + "/sub/ownCloud/")));
        //  QVERIFY (folder_manager.addFolder (new_account_state.data (), folder_definition (directory_path + "/ownCloud2/")));

        // TEST

        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/oc", url),
        //           string (directory_path + "/oc"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud", url),
        //           string (directory_path + "/ownCloud3"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2", url),
        //           string (directory_path + "/ownCloud22"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2/foo", url),
        //           string (directory_path + "/ownCloud2/foo"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2/bar", url),
        //           string (directory_path + "/ownCloud2/bar"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/sub", url),
        //           string (directory_path + "/sub2"));

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        // We should still not suggest this folder as a new folder.
        QDir (directory_path + "/ownCloud2/").removeRecursively ();
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud", url),
        //      string (directory_path + "/ownCloud3"));
        //  QCOMPARE (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2", url),
        //      string (directory_path + "/ownCloud22"));
    }

}
}
