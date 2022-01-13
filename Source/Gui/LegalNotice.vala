/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
    class LegalNotice;
}

/***********************************************************
@brief The LegalNotice class
@ingroup gui
***********************************************************/
class LegalNotice : Gtk.Dialog {

public:
    LegalNotice (Gtk.Dialog *parent = nullptr);
    ~LegalNotice () override;

protected:
    void changeEvent (QEvent *) override;

private:
    void customizeStyle ();

    Ui.LegalNotice *_ui;
};

    LegalNotice.LegalNotice (Gtk.Dialog *parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.LegalNotice) {
        _ui.setupUi (this);
    
        connect (_ui.closeButton, &QPushButton.clicked, this, &LegalNotice.accept);
    
        customizeStyle ();
    }
    
    LegalNotice.~LegalNotice () {
        delete _ui;
    }
    
    void LegalNotice.changeEvent (QEvent *e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customizeStyle ();
            break;
        default:
            break;
        }
    
        Gtk.Dialog.changeEvent (e);
    }
    
    void LegalNotice.customizeStyle () {
        string notice = tr ("<p>Copyright 2017-2021 Nextcloud GmbH<br />"
                            "Copyright 2012-2021 ownCloud GmbH</p>");
    
        notice += tr ("<p>Licensed under the GNU General Public License (GPL) Version 2.0 or any later version.</p>");
    
        notice += "<p>&nbsp;</p>";
        notice += Theme.instance ().aboutDetails ();
    
        Theme.replaceLinkColorStringBackgroundAware (notice);
    
        _ui.notice.setTextInteractionFlags (Qt.TextSelectableByMouse | Qt.TextBrowserInteraction);
        _ui.notice.setText (notice);
        _ui.notice.setWordWrap (true);
        _ui.notice.setOpenExternalLinks (true);
    }
    
    } // namespace Occ
    