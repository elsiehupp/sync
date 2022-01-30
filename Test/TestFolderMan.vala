/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <qglobal.h>
// #include <QTemporaryDir>
// #include <QtTest>

using namespace Occ;

class TestFolderMan : public GLib.Object {

    FolderMan _fm;

    private on_ void testCheckPathValidityForNewFolder () {
        QTemporaryDir dir;
        ConfigFile.setConfDir (dir.path ()); // we don't want to pollute the user's config file
        QVERIFY (dir.isValid ());
        QDir dir2 (dir.path ());
        QVERIFY (dir2.mkpath ("sub/ownCloud1/folder/f"));
        QVERIFY (dir2.mkpath ("ownCloud2"));
        QVERIFY (dir2.mkpath ("sub/free"));
        QVERIFY (dir2.mkpath ("free2/sub")); {
            GLib.File f (dir.path () + "/sub/file.txt");
            f.open (GLib.File.WriteOnly);
            f.write ("hello");
        }
        string dirPath = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url ("http://example.de");
        var cred = new HttpCredentialsTest ("testuser", "secret");
        account.setCredentials (cred);
        account.setUrl ( url );

        AccountStatePtr newAccountState (new AccountState (account));
        FolderMan folderman = FolderMan.instance ();
        QCOMPARE (folderman, &_fm);
        QVERIFY (folderman.addFolder (newAccountState.data (), folderDefinition (dirPath + "/sub/ownCloud1")));
        QVERIFY (folderman.addFolder (newAccountState.data (), folderDefinition (dirPath + "/ownCloud2")));

        const var folderList = folderman.map ();

        for (var &folder : folderList) {
            QVERIFY (!folder.isSyncRunning ());
        }

        // those should be allowed
        // string FolderMan.checkPathValidityForNewFolder (string& path, GLib.Uri serverUrl, bool forNewDirectory)

        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/sub/free"), string ());
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/free2/"), string ());
        // Not an existing directory . Ok
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/sub/bliblablu"), string ());
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/sub/free/bliblablu"), string ());
        // QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/sub/bliblablu/some/more"), string ());

        // A file . Error
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/file.txt").isNull ());

        // There are folders configured in those folders, url needs to be taken into account : . ERROR
        GLib.Uri url2 (url);
        const string user = account.credentials ().user ();
        url2.setUserName (user);

        // The following both fail because they refer to the same account (user and url)
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1", url2).isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/ownCloud2/", url2).isNull ());

        // Now it will work because the account is different
        GLib.Uri url3 ("http://anotherexample.org");
        url3.setUserName ("dummy");
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1", url3), string ());
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/ownCloud2/", url3), string ());

        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath).isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1/folder").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1/folder/f").isNull ());

        // make a bunch of links
        QVERIFY (GLib.File.link (dirPath + "/sub/free", dirPath + "/link1"));
        QVERIFY (GLib.File.link (dirPath + "/sub", dirPath + "/link2"));
        QVERIFY (GLib.File.link (dirPath + "/sub/ownCloud1", dirPath + "/link3"));
        QVERIFY (GLib.File.link (dirPath + "/sub/ownCloud1/folder", dirPath + "/link4"));

        // Ok
        QVERIFY (folderman.checkPathValidityForNewFolder (dirPath + "/link1").isNull ());
        QVERIFY (folderman.checkPathValidityForNewFolder (dirPath + "/link2/free").isNull ());

        // Not Ok
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/link2").isNull ());

        // link 3 points to an existing sync folder. To make it fail, the account must be the same
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/link3", url2).isNull ());
        // while with a different account, this is fine
        QCOMPARE (folderman.checkPathValidityForNewFolder (dirPath + "/link3", url3), string ());

        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/link4").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/link3/folder").isNull ());

        // test some non existing sub path (error)
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1/some/sub/path").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/ownCloud2/blublu").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/sub/ownCloud1/folder/g/h").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/link3/folder/neu_folder").isNull ());

        // Subfolder of links
        QVERIFY (folderman.checkPathValidityForNewFolder (dirPath + "/link1/subfolder").isNull ());
        QVERIFY (folderman.checkPathValidityForNewFolder (dirPath + "/link2/free/subfolder").isNull ());

        // Should not have the rights
        QVERIFY (!folderman.checkPathValidityForNewFolder ("/").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder ("/usr/bin/somefolder").isNull ());

        // Invalid paths
        QVERIFY (!folderman.checkPathValidityForNewFolder ("").isNull ());

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        QDir (dirPath + "/ownCloud2/").removeRecursively ();
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/ownCloud2/blublu").isNull ());
        QVERIFY (!folderman.checkPathValidityForNewFolder (dirPath + "/ownCloud2/sub/subsub/sub").isNull ());
    }

    private on_ void testFindGoodPathForNewSyncFolder () {
        // SETUP

        QTemporaryDir dir;
        ConfigFile.setConfDir (dir.path ()); // we don't want to pollute the user's config file
        QVERIFY (dir.isValid ());
        QDir dir2 (dir.path ());
        QVERIFY (dir2.mkpath ("sub/ownCloud1/folder/f"));
        QVERIFY (dir2.mkpath ("ownCloud"));
        QVERIFY (dir2.mkpath ("ownCloud2"));
        QVERIFY (dir2.mkpath ("ownCloud2/foo"));
        QVERIFY (dir2.mkpath ("sub/free"));
        QVERIFY (dir2.mkpath ("free2/sub"));
        string dirPath = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url ("http://example.de");
        var cred = new HttpCredentialsTest ("testuser", "secret");
        account.setCredentials (cred);
        account.setUrl ( url );
        url.setUserName (cred.user ());

        AccountStatePtr newAccountState (new AccountState (account));
        FolderMan folderman = FolderMan.instance ();
        QCOMPARE (folderman, &_fm);
        QVERIFY (folderman.addFolder (newAccountState.data (), folderDefinition (dirPath + "/sub/ownCloud/")));
        QVERIFY (folderman.addFolder (newAccountState.data (), folderDefinition (dirPath + "/ownCloud2/")));

        // TEST

        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/oc", url),
                 string (dirPath + "/oc"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud", url),
                 string (dirPath + "/ownCloud3"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud2", url),
                 string (dirPath + "/ownCloud22"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud2/foo", url),
                 string (dirPath + "/ownCloud2/foo"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud2/bar", url),
                 string (dirPath + "/ownCloud2/bar"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/sub", url),
                 string (dirPath + "/sub2"));

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        // We should still not suggest this folder as a new folder.
        QDir (dirPath + "/ownCloud2/").removeRecursively ();
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud", url),
            string (dirPath + "/ownCloud3"));
        QCOMPARE (folderman.findGoodPathForNewSyncFolder (dirPath + "/ownCloud2", url),
            string (dirPath + "/ownCloud22"));
    }
};

QTEST_APPLESS_MAIN (TestFolderMan)
#include "testfolderman.moc"
