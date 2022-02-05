/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLabel>

namespace Occ {
namespace Ui {

class Link_label : QLabel {

    /***********************************************************
    ***********************************************************/
    public Link_label (Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public void url (GLib.Uri url);

signals:
    void clicked ();


    protected void enter_event (QEvent event) override;

    protected void leave_event (QEvent event) override;

    protected void mouse_release_event (QMouse_event event) override;


    /***********************************************************
    ***********************************************************/
    private void font_underline (bool value);

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;
}

    Link_label.Link_label (Gtk.Widget parent) : QLabel (parent) {

    }

    void Link_label.url (GLib.Uri url) {
        this.url = url;
    }

    void Link_label.enter_event (QEvent * /*event*/) {
        font_underline (true);
        cursor (Qt.PointingHandCursor);
    }

    void Link_label.leave_event (QEvent * /*event*/) {
        font_underline (false);
        cursor (Qt.ArrowCursor);
    }

    void Link_label.mouse_release_event (QMouse_event * /*event*/) {
        if (url.is_valid ()) {
            Utility.open_browser (url);
        }

        /* emit */ clicked ();
    }

    void Link_label.font_underline (bool value) {
        var label_font = font ();
        label_font.underline (value);
        font (label_font);
    }

    }
    