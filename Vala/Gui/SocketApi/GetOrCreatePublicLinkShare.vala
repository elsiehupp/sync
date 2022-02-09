/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// don't pull the share manager into socketapi unittests
//  #ifndef OWNCLOUD_TEST

namespace Occ {
namespace Ui {

class Get_or_create_public_link_share : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Get_or_create_public_link_share (AccountPointer account, string local_file,
        GLib.Object parent)
        : GLib.Object (parent)
        this.account (account)
        this.share_manager (account)
        this.local_file (local_file) {
        connect (&this.share_manager, &Share_manager.on_signal_shares_fetched,
            this, &Get_or_create_public_link_share.on_signal_shares_fetched);
        connect (&this.share_manager, &Share_manager.on_signal_link_share_created,
            this, &Get_or_create_public_link_share.on_signal_link_share_created);
        connect (&this.share_manager, &Share_manager.on_signal_link_share_requires_password,
            this, &Get_or_create_public_link_share.on_signal_link_share_requires_password);
        connect (&this.share_manager, &Share_manager.on_signal_server_error,
            this, &Get_or_create_public_link_share.on_signal_server_error);
    }


    /***********************************************************
    ***********************************************************/
    public void run () {
        GLib.debug ("Fetching shares";
        this.share_manager.fetch_shares (this.local_file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (GLib.List<unowned<Share>> shares) {
        var share_name = SocketApi._("Context menu share");

        // If there already is a context menu share, reuse it
        for (var share : shares) {
            const var link_share = q_shared_pointer_dynamic_cast<Link_share> (share);
            if (!link_share)
                continue;

            if (link_share.get_name () == share_name) {
                GLib.debug ("Found existing share, reusing";
                return on_signal_success (link_share.get_link ().to_string ());
            }
        }

        // otherwise create a new one
        GLib.debug ("Creating new share";
        this.share_manager.create_link_share (this.local_file, share_name, "");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_created (unowned<Link_share> share) {
        GLib.debug ("New share created";
        on_signal_success (share.get_link ().to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_password_required () {
        bool ok = false;
        string password = QInputDialog.get_text (null,
                                                 _("Password for share required"),
                                                 _("Please enter a password for your link share:"),
                                                 QLineEdit.Normal,
                                                 "",
                                                 ok);

        if (!ok) {
            // The dialog was canceled so no need to do anything
            return;
        }

        // Try to create the link share again with the newly entered password
        this.share_manager.create_link_share (this.local_file, "", password);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_requires_password (string message) {
        GLib.info ("Could not create link share:" + message;
        /* emit */ error (message);
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_server_error (int code, string message) {
        GLib.warn ("Share fetch/create error" + code + message;
        QMessageBox.warning (
            null,
            _("Sharing error"),
            _("Could not retrieve or create the public link share. Error:\n\n%1").arg (message),
            QMessageBox.Ok,
            QMessageBox.NoButton);
        /* emit */ error (message);
        delete_later ();
    }

signals:
    void on_signal_done (string link);
    void error (string message);


    /***********************************************************
    ***********************************************************/
    private void on_signal_success (string link) {
        /* emit */ done (link);
        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private Share_manager this.share_manager;
    private string this.local_file;
}

#else

class Get_or_create_public_link_share : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Get_or_create_public_link_share (AccountPointer &, string ,
        std.function<void (string link)>, GLib.Object *) {
    }


    /***********************************************************
    ***********************************************************/
    public void run () {
    }
}

//  #endif