namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestFolderMan

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class AbstractTestFolderMan { //: GLib.Object {

    LibSync.Account account
    AccountState account_state;
    FolderManager folder_manager;
    GLib.Uri url

    protected AbstractTestFolderMan () {
        //  this.account = LibSync.Account.create ();
        //  this.url = new GLib.Uri ("http://example.de");
        //  this.var credentials = new HttpCredentialsTest ("testuser", "secret");
        //  this.account.set_credentials (this.credentials);
        //  this.account.set_url (this.url);
        //  this.url.set_user_name (this.credentials.user ());
        //  this.account_state = new AccountState (this.account);
        //  this.folder_manager = FolderManager.instance;
    }

} // class AbstractTestFolderMan

} // namespace Testing
} // namespace Occ
