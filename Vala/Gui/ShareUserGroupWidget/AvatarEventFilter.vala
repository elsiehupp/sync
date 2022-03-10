/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class AvatarEventFilter : GLib.Object {

    signal void signal_clicked ();
    signal void signal_context_menu (QPoint global_position);

    /***********************************************************
    ***********************************************************/
    public AvatarEventFilter (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    protected override bool event_filter (GLib.Object object, QEvent event) {
        if (event.type () == QEvent.Context_menu) {
            const var context_menu_event = dynamic_cast<QContext_menu_event> (event);
            if (!context_menu_event) {
                return false;
            }
            /* emit */ context_menu (context_menu_event.global_pos ());
            return true;
        }
        return GLib.Object.event_filter (object, event);
    }

} // class AvatarEventFilter

} // namespace Ui
} // namespace Occ
