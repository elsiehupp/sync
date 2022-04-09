/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <qglobal.h>
//  #include <GLib.TemporaryDir>

namespace Occ {
namespace Testing {

public class TestRemoteWipe : GLib.Object {

    /***********************************************************
    ***********************************************************/
    // TODO
    private TestRemoteWipe () {
//        GLib.TemporaryDir directory;
//        ConfigFile.set_configuration_directory (directory.path); // we don't want to pollute the user's config file
//        GLib.assert_true (directory.is_valid);

//        GLib.Dir dir_to_remove = new GLib.Dir (directory.path);
//        GLib.assert_true (dir_to_remove.mkpath ("nextcloud"));

//        string directory_path = dir_to_remove.canonical_path;

//        unowned Account account = Account.create ();
//        GLib.assert_true (account);

//        var manager = AccountManager.instance;
//        GLib.assert_true (manager);

//        AccountState new_account_state = manager.add_account (account);
//        manager.save ();
//        GLib.assert_true (new_account_state);

//        GLib.Uri url ("http://example.de");
//        HttpCredentialsTest credentials = new HttpCredentialsTest ("testuser", "secret");
//        account.set_credentials (credentials);
//        account.set_url ( url );

//        FolderManager folder_manager = FolderManager.instance;
//        folder_manager.add_folder (new_account_state, folder_definition (directory_path + "/sub/nextcloud/"));

//        // check if account exists
//        GLib.debug ("Does account exists?!";
//        GLib.assert_true (!account.identifier == "");

//        manager.delete_account (new_account_state);
//        manager.save ();

//        // check if account exists
//        GLib.debug ("Does account exists yet?!";
//        GLib.assert_true (account);

//        // check if folder exists
//        GLib.assert_true (dir_to_remove.exists ());

//        // remote folders
//        GLib.debug () +  "Removing folder for account " + new_account_state.account.url;

//        folder_manager.on_signal_wipe_folder_for_account (new_account_state);

//        // check if folders dont exist anymore
//        GLib.assert_true (dir_to_remove.exists () == false);
    }

} // class TestRemoteWipe

} // namespace Testing
} // namespace Occ
