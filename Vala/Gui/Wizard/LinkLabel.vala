/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Label>

namespace Occ {
namespace Ui {

class LinkLabel : Gtk.Label {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;


    signal void clicked ();


    /***********************************************************
    ***********************************************************/
    public LinkLabel (Gtk.Widget parent = null) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public void url (GLib.Uri url);
    void LinkLabel.url (GLib.Uri url) {
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    protected void enter_event (QEvent event) {
        font_underline (true);
        cursor (Qt.PointingHandCursor);
    }


    /***********************************************************
    ***********************************************************/
    protected void leave_event (QEvent event) {
        font_underline (false);
        cursor (Qt.ArrowCursor);
    }


    /***********************************************************
    ***********************************************************/
    protected void mouse_release_event (QMouseEvent event) {
        if (url.is_valid ()) {
            Utility.open_browser (url);
        }

        /* emit */ clicked ();
    }


    /***********************************************************
    ***********************************************************/
    private void font_underline (bool value) {
        var label_font = font ();
        label_font.underline (value);
        font (label_font);
    }

} // class LinkLabel

} // namespace Ui
} // namespace Occ
