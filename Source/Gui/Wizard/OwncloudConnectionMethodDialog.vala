/***********************************************************
Copyright (C) 2015 by Jeroen Hoek
Copyright (C) 2015 by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QUrl>
// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class OwncloudConnectionMethodDialog;
}

/***********************************************************
@brief The OwncloudConnectionMethodDialog class
@ingroup gui
***********************************************************/
class OwncloudConnectionMethodDialog : Gtk.Dialog {

public:
    OwncloudConnectionMethodDialog (Gtk.Widget *parent = nullptr);
    ~OwncloudConnectionMethodDialog () override;
    enum {
        Closed = 0,
        No_TLS,
        Client_Side_TLS,
        Back
    };

    // The URL that was tried
    void setUrl (QUrl &);

public slots:
    void returnNoTLS ();
    void returnClientSideTLS ();
    void returnBack ();

private:
    Ui.OwncloudConnectionMethodDialog *ui;
};

    OwncloudConnectionMethodDialog.OwncloudConnectionMethodDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent, Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint)
        , ui (new Ui.OwncloudConnectionMethodDialog) {
        ui.setupUi (this);
    
        connect (ui.btnNoTLS, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.returnNoTLS);
        connect (ui.btnClientSideTLS, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.returnClientSideTLS);
        connect (ui.btnBack, &QAbstractButton.clicked, this, &OwncloudConnectionMethodDialog.returnBack);
    }
    
    void OwncloudConnectionMethodDialog.setUrl (QUrl &url) {
        ui.label.setText (tr ("<html><head/><body><p>Failed to connect to the secure server address <em>%1</em>. How do you wish to proceed?</p></body></html>").arg (url.toDisplayString ().toHtmlEscaped ()));
    }
    
    void OwncloudConnectionMethodDialog.returnNoTLS () {
        done (No_TLS);
    }
    
    void OwncloudConnectionMethodDialog.returnClientSideTLS () {
        done (Client_Side_TLS);
    }
    
    void OwncloudConnectionMethodDialog.returnBack () {
        done (Back);
    }
    
    OwncloudConnectionMethodDialog.~OwncloudConnectionMethodDialog () {
        delete ui;
    }
    }
    