#pragma once

//  #include <QBox_layout>
//  #include <QLabel>
//  #include <account.h>
//  #include <QMenu>
//  #include <cstddef>

namespace Occ {

class Profile_page_menu : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public Profile_page_menu (AccountPointer account, string share_with_user_id, Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public void exec (QPoint global_position);


    /***********************************************************
    ***********************************************************/
    private void on_hovercard_fetched ();

    /***********************************************************
    ***********************************************************/
    private 
    private OcsProfileConnector this.profile_connector;
    private QMenu this.menu;
}


    Profile_page_menu.Profile_page_menu (AccountPointer account, string share_with_user_id, Gtk.Widget parent)
        : Gtk.Widget (parent)
        this.profile_connector (account) {
        connect (&this.profile_connector, &OcsProfileConnector.hovercard_fetched, this, &Profile_page_menu.on_hovercard_fetched);
        connect (&this.profile_connector, &OcsProfileConnector.icon_loaded, this, &Profile_page_menu.on_icon_loaded);
        this.profile_connector.fetch_hovercard (share_with_user_id);
    }

    Profile_page_menu.~Profile_page_menu () = default;

    void Profile_page_menu.exec (QPoint global_position) {
        this.menu.exec (global_position);
    }

    void Profile_page_menu.on_hovercard_fetched () {
        this.menu.clear ();

        const var hovercard_actions = this.profile_connector.hovercard ().actions;
        for (var hovercard_action : hovercard_actions) {
            const var action = this.menu.add_action (hovercard_action.icon, hovercard_action.title);
            const var link = hovercard_action.link;
            connect (action, &QAction.triggered, action, [link] (bool) {
                Utility.open_browser (link);
            });
        }
    }

    void Profile_page_menu.on_icon_loaded (size_t hovercard_action_index) {
        const var hovercard_actions = this.profile_connector.hovercard ().actions;
        const var menu_actions = this.menu.actions ();
        if (hovercard_action_index >= hovercard_actions.size ()
            || hovercard_action_index >= static_cast<size_t> (menu_actions.size ())) {
            return;
        }
        const var menu_action = menu_actions[static_cast<int> (hovercard_action_index)];
        menu_action.icon (hovercard_actions[hovercard_action_index].icon);
    }
    }
    