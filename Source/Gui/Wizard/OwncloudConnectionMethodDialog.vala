/***********************************************************
Copyright (C) 2015 by Jeroen Hoek
Copyright (C) 2015 by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QUrl>
// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class Owncloud_connection_method_dialog;
}

/***********************************************************
@brief The Owncloud_connection_method_dialog class
@ingroup gui
***********************************************************/
class Owncloud_connection_method_dialog : Gtk.Dialog {

public:
    Owncloud_connection_method_dialog (Gtk.Widget *parent = nullptr);
    ~Owncloud_connection_method_dialog () override;
    enum {
        Closed = 0,
        No_TLS,
        Client_Side_TLS,
        Back
    };

    // The URL that was tried
    void set_url (QUrl &);

public slots:
    void return_no_tLS ();
    void return_client_side_tLS ();
    void return_back ();

private:
    Ui.Owncloud_connection_method_dialog *ui;
};

    Owncloud_connection_method_dialog.Owncloud_connection_method_dialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent, Qt.Customize_window_hint | Qt.Window_title_hint | Qt.Window_close_button_hint | Qt.MSWindows_fixed_size_dialog_hint)
        , ui (new Ui.Owncloud_connection_method_dialog) {
        ui.setup_ui (this);
    
        connect (ui.btn_no_tLS, &QAbstractButton.clicked, this, &Owncloud_connection_method_dialog.return_no_tLS);
        connect (ui.btn_client_side_tLS, &QAbstractButton.clicked, this, &Owncloud_connection_method_dialog.return_client_side_tLS);
        connect (ui.btn_back, &QAbstractButton.clicked, this, &Owncloud_connection_method_dialog.return_back);
    }
    
    void Owncloud_connection_method_dialog.set_url (QUrl &url) {
        ui.label.set_text (tr ("<html><head/><body><p>Failed to connect to the secure server address <em>%1</em>. How do you wish to proceed?</p></body></html>").arg (url.to_display_string ().to_html_escaped ()));
    }
    
    void Owncloud_connection_method_dialog.return_no_tLS () {
        done (No_TLS);
    }
    
    void Owncloud_connection_method_dialog.return_client_side_tLS () {
        done (Client_Side_TLS);
    }
    
    void Owncloud_connection_method_dialog.return_back () {
        done (Back);
    }
    
    Owncloud_connection_method_dialog.~Owncloud_connection_method_dialog () {
        delete ui;
    }
    }
    