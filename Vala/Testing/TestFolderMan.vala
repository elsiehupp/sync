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
        GLib.assert_true (directory.is_valid ());
        QDir dir2 = new QDir (directory.path ());
        GLib.assert_true (dir2.mkpath ("sub/ownCloud1/folder/file"));
        GLib.assert_true (dir2.mkpath ("ownCloud2"));
        GLib.assert_true (dir2.mkpath ("sub/free"));
        GLib.assert_true (dir2.mkpath ("free2/sub")); {
        //      GLib.File file = new GLib.File (directory.path () + "/sub/file.txt");
        //      file.open (GLib.File.WriteOnly);
        //      file.write ("hello");
        //  }
        string directory_path = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.set_credentials (credentials);
        account.set_url ( url );

        AccountStatePtr new_account_state = new AccountStatePtr (new AccountState (account));
        FolderMan folder_manager = FolderMan.instance ();
        GLib.assert_cmp (folder_manager, this.folder_manager);
        GLib.assert_true (folder_manager.add_folder (new_account_state.data (), folder_definition (directory_path + "/sub/ownCloud1")));
        GLib.assert_true (folder_manager.add_folder (new_account_state.data (), folder_definition (directory_path + "/ownCloud2")));

        var folder_list = folder_manager.map ();

        //  foreach (var folder in folder_list) {
        //      GLib.assert_true (!folder.isSyncRunning ());
        //  }

        // those should be allowed
        // string FolderMan.checkPathValidityForNewFolder (string path, GLib.Uri serverUrl, bool forNewDirectory)

        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/free"), "");
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/free2/"), "");
        // Not an existing directory . Ok
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/bliblablu"), "");
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/free/bliblablu"), "");
        // GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/bliblablu/some/more"), "");

        // A file . Error
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/file.txt").is_null ());

        // There are folders configured in those folders, url needs to be taken into account : . ERROR
        GLib.Uri url2 = new GLib.Uri (url);
        const string user = account.credentials ().user ();
        url2.set_user_name (user);

        // The following both fail because they refer to the same account (user and url)
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1", url2).is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/", url2).is_null ());

        // Now it will work because the account is different
        GLib.Uri url3 = new GLib.Uri ("http://anotherexample.org");
        url3.set_user_name ("dummy");
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1", url3), "");
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/", url3), "");

        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path).is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder/file").is_null ());

        // make a bunch of links
        GLib.assert_true (GLib.File.link (directory_path + "/sub/free", directory_path + "/link1"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub", directory_path + "/link2"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub/ownCloud1", directory_path + "/link3"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub/ownCloud1/folder", directory_path + "/link4"));

        // Ok
        GLib.assert_true (folder_manager.checkPathValidityForNewFolder (directory_path + "/link1").is_null ());
        GLib.assert_true (folder_manager.checkPathValidityForNewFolder (directory_path + "/link2/free").is_null ());

        // Not Ok
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link2").is_null ());

        // link 3 points to an existing sync folder. To make it fail, the account must be the same
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3", url2).is_null ());
        // while with a different account, this is fine
        GLib.assert_cmp (folder_manager.checkPathValidityForNewFolder (directory_path + "/link3", url3), "");

        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link4").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3/folder").is_null ());

        // test some non existing sub path (error)
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/some/sub/path").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/blublu").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/sub/ownCloud1/folder/g/h").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/link3/folder/neu_folder").is_null ());

        // Subfolder of links
        GLib.assert_true (folder_manager.checkPathValidityForNewFolder (directory_path + "/link1/subfolder").is_null ());
        GLib.assert_true (folder_manager.checkPathValidityForNewFolder (directory_path + "/link2/free/subfolder").is_null ());

        // Should not have the rights
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder ("/").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder ("/usr/bin/somefolder").is_null ());

        // Invalid paths
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder ("").is_null ());

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        QDir (directory_path + "/ownCloud2/").remove_recursively ();
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/blublu").is_null ());
        GLib.assert_true (!folder_manager.checkPathValidityForNewFolder (directory_path + "/ownCloud2/sub/subsub/sub").is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void testFindGoodPathForNewSyncFolder () {
        // SETUP

        QTemporaryDir directory;
        ConfigFile.setConfDir (directory.path ()); // we don't want to pollute the user's config file
        GLib.assert_true (directory.is_valid ());
        QDir dir2 = new QDir (directory.path ());
        GLib.assert_true (dir2.mkpath ("sub/ownCloud1/folder/file"));
        GLib.assert_true (dir2.mkpath ("ownCloud"));
        GLib.assert_true (dir2.mkpath ("ownCloud2"));
        GLib.assert_true (dir2.mkpath ("ownCloud2/foo"));
        GLib.assert_true (dir2.mkpath ("sub/free"));
        GLib.assert_true (dir2.mkpath ("free2/sub"));
        string directory_path = dir2.canonicalPath ();

        AccountPointer account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.set_credentials (credentials);
        account.set_url (url);
        url.set_user_name (credentials.user ());

        AccountStatePtr new_account_state = new AccountStatePtr (new AccountState (account));
        FolderMan folder_manager = FolderMan.instance ();
        GLib.assert_cmp (folder_manager, this.folder_manager);
        GLib.assert_true (folder_manager.add_folder (new_account_state.data (), folder_definition (directory_path + "/sub/ownCloud/")));
        GLib.assert_true (folder_manager.add_folder (new_account_state.data (), folder_definition (directory_path + "/ownCloud2/")));

        // TEST

        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/oc", url),
        //           string (directory_path + "/oc"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud", url),
        //           string (directory_path + "/ownCloud3"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2", url),
        //           string (directory_path + "/ownCloud22"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2/foo", url),
        //           string (directory_path + "/ownCloud2/foo"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2/bar", url),
        //           string (directory_path + "/ownCloud2/bar"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/sub", url),
        //           string (directory_path + "/sub2"));

        // REMOVE ownCloud2 from the filesystem, but keep a folder sync'ed to it.
        // We should still not suggest this folder as a new folder.
        QDir (directory_path + "/ownCloud2/").remove_recursively ();
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud", url),
        //      string (directory_path + "/ownCloud3"));
        GLib.assert_cmp (folder_manager.findGoodPathForNewSyncFolder (directory_path + "/ownCloud2", url),
        //      string (directory_path + "/ownCloud22"));
    }

}
}
