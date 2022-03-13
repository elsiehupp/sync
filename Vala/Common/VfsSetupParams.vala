/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
Collection of parameters for initializing a Vfs instance.
OCSYNC_EXPORT
***********************************************************/
struct VfsSetupParams {
    /***********************************************************
    The full path to the folder on the local filesystem

    Always ends with /.
    ***********************************************************/
    string filesystem_path;


    /***********************************************************
    Folder display name in Windows Explorer
    ***********************************************************/
    string display_name;


    /***********************************************************
    Folder alias
    ***********************************************************/
    string alias;


    /***********************************************************
    The path to the synced folder on the account

    Always ends with /.
    ***********************************************************/
    string remote_path;


    /***********************************************************
    Account url, credentials etc for network calls
    ***********************************************************/
    unowned Account account;


    /***********************************************************
    Access to the sync folder's database.

    Note: The journal must live at least until the Vfs.stop () call.
    ***********************************************************/
    SyncJournalDb journal = null;


    /***********************************************************
    Strings potentially passed on to the platform
    ***********************************************************/
    string provider_name;


    /***********************************************************
    ***********************************************************/
    string provider_version;


    /***********************************************************
    When registering with the system we might use a different
    presentaton to identify the accounts
    ***********************************************************/
    bool multiple_accounts_registered = false;
};