/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

public class LinkLabel : Gtk.Label {

    /***********************************************************
    ***********************************************************/
    GLib.Uri url { private get; public set; }

    internal signal void clicked ();

    /***********************************************************
    ***********************************************************/
    public LinkLabel (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
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
            OpenExtrernal.open_browser (url);
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
