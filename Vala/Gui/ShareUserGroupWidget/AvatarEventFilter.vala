/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class Avatar_event_filter : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Avatar_event_filter (GLib.Object parent = new GLib.Object ());

signals:
    void clicked ();
    void context_menu (QPoint global_position);


    protected bool event_filter (GLib.Object obj, QEvent event) override;
}



    Avatar_event_filter.Avatar_event_filter (GLib.Object parent) {
        base (parent);
    }

    bool Avatar_event_filter.event_filter (GLib.Object obj, QEvent event) {
        if (event.type () == QEvent.Context_menu) {
            const var context_menu_event = dynamic_cast<QContext_menu_event> (event);
            if (!context_menu_event) {
                return false;
            }
            /* emit */ context_menu (context_menu_event.global_pos ());
            return true;
        }
        return GLib.Object.event_filter (obj, event);
    }