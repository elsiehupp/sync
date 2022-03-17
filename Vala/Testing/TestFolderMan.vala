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

public class TestFolderMan : GLib.Object {

    FolderMan folder_manager;

    /***********************************************************
    ***********************************************************/
    private void test_check_path_validity_for_new_folder () {
        QTemporaryDir directory;
        ConfigFile.set_configuration_directory (directory.path ()); // we don't want to pollute the user's config file
        GLib.assert_true (directory.is_valid ());
        GLib.Dir dir2 = new GLib.Dir (directory.path ());
        GLib.assert_true (dir2.mkpath ("sub/own_cloud1/folder/file"));
        GLib.assert_true (dir2.mkpath ("own_cloud2"));
        GLib.assert_true (dir2.mkpath ("sub/free"));
        GLib.assert_true (dir2.mkpath ("free2/sub")); {
            GLib.File file = new GLib.File (directory.path () + "/sub/file.txt");
            file.open (GLib.File.WriteOnly);
            file.write ("hello");
        }
        string directory_path = dir2.canonical_path ();

        Account account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.set_credentials (credentials);
        account.set_url ( url );

        AccountState new_account_state = new AccountState (account);
        FolderMan folder_manager = FolderMan.instance;
        GLib.assert_true (folder_manager == this.folder_manager);
        GLib.assert_true (folder_manager.add_folder (new_account_state, folder_definition (directory_path + "/sub/own_cloud1")));
        GLib.assert_true (folder_manager.add_folder (new_account_state, folder_definition (directory_path + "/own_cloud2")));

        var folder_list = folder_manager.map ();

        //  foreach (var folder in folder_list) {
        //      GLib.assert_true (!folder.is_sync_running ());
        //  }

        // those should be allowed
        // string FolderMan.check_path_validity_for_new_folder (string path, GLib.Uri server_url, bool for_new_directory)

        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/free") == "");
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/free2/") == "");
        // Not an existing directory . Ok
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/bliblablu") == "");
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/free/bliblablu") == "");
        // GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/bliblablu/some/more") == "");

        // A file . Error
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/file.txt").is_null ());

        // There are folders configured in those folders, url needs to be taken into account : . ERROR
        GLib.Uri url2 = new GLib.Uri (url);
        const string user = account.credentials ().user ();
        url2.set_user_name (user);

        // The following both fail because they refer to the same account (user and url)
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1", url2).is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/own_cloud2/", url2).is_null ());

        // Now it will work because the account is different
        GLib.Uri url3 = new GLib.Uri ("http://anotherexample.org");
        url3.set_user_name ("dummy");
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1", url3) == "");
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/own_cloud2/", url3) == "");

        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path).is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1/folder").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1/folder/file").is_null ());

        // make a bunch of links
        GLib.assert_true (GLib.File.link (directory_path + "/sub/free", directory_path + "/link1"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub", directory_path + "/link2"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub/own_cloud1", directory_path + "/link3"));
        GLib.assert_true (GLib.File.link (directory_path + "/sub/own_cloud1/folder", directory_path + "/link4"));

        // Ok
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/link1").is_null ());
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/link2/free").is_null ());

        // Not Ok
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/link2").is_null ());

        // link 3 points to an existing sync folder. To make it fail, the account must be the same
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/link3", url2).is_null ());
        // while with a different account, this is fine
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/link3", url3) == "");

        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/link4").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/link3/folder").is_null ());

        // test some non existing sub path (error)
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1/some/sub/path").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/own_cloud2/blublu").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/sub/own_cloud1/folder/g/h").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/link3/folder/neu_folder").is_null ());

        // Subfolder of links
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/link1/subfolder").is_null ());
        GLib.assert_true (folder_manager.check_path_validity_for_new_folder (directory_path + "/link2/free/subfolder").is_null ());

        // Should not have the rights
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder ("/").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder ("/usr/bin/somefolder").is_null ());

        // Invalid paths
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder ("").is_null ());

        // REMOVE own_cloud2 from the filesystem, but keep a folder sync'ed to it.
        GLib.Dir (directory_path + "/own_cloud2/").remove_recursively ();
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/own_cloud2/blublu").is_null ());
        GLib.assert_true (!folder_manager.check_path_validity_for_new_folder (directory_path + "/own_cloud2/sub/subsub/sub").is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_find_good_path_for_new_sync_folder () {
        // SETUP

        QTemporaryDir directory;
        ConfigFile.set_configuration_directory (directory.path ()); // we don't want to pollute the user's config file
        GLib.assert_true (directory.is_valid ());
        GLib.Dir dir2 = new GLib.Dir (directory.path ());
        GLib.assert_true (dir2.mkpath ("sub/own_cloud1/folder/file"));
        GLib.assert_true (dir2.mkpath ("own_cloud"));
        GLib.assert_true (dir2.mkpath ("own_cloud2"));
        GLib.assert_true (dir2.mkpath ("own_cloud2/foo"));
        GLib.assert_true (dir2.mkpath ("sub/free"));
        GLib.assert_true (dir2.mkpath ("free2/sub"));
        string directory_path = dir2.canonical_path ();

        Account account = Account.create ();
        GLib.Uri url = new GLib.Uri ("http://example.de");
        var credentials = new HttpCredentialsTest ("testuser", "secret");
        account.set_credentials (credentials);
        account.set_url (url);
        url.set_user_name (credentials.user ());

        AccountState new_account_state = new AccountState (account);
        FolderMan folder_manager = FolderMan.instance;
        GLib.assert_true (folder_manager == this.folder_manager);
        GLib.assert_true (folder_manager.add_folder (new_account_state, folder_definition (directory_path + "/sub/own_cloud/")));
        GLib.assert_true (folder_manager.add_folder (new_account_state, folder_definition (directory_path + "/own_cloud2/")));

        // TEST

        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/oc", url) ==
            directory_path + "/oc");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud", url) ==
            directory_path + "/own_cloud3");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2", url) ==
            directory_path + "/own_cloud22");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2/foo", url) ==
            directory_path + "/own_cloud2/foo");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2/bar", url) ==
            directory_path + "/own_cloud2/bar");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/sub", url) ==
            directory_path + "/sub2");

        // REMOVE own_cloud2 from the filesystem, but keep a folder sync'ed to it.
        // We should still not suggest this folder as a new folder.
        GLib.Dir (directory_path + "/own_cloud2/").remove_recursively ();
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud", url) ==
            directory_path + "/own_cloud3");
        GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2", url) ==
            directory_path + "/own_cloud22");
    }

}
}
