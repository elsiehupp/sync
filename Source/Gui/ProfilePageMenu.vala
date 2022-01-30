#pragma once

// #include <QBox_layout>
// #include <QLabel>
// #include <account.h>
// #include <QMenu>

// #include <cstddef>

namespace Occ {

class Profile_page_menu : Gtk.Widget {

    public Profile_page_menu (AccountPointer account, string share_with_user_id, Gtk.Widget parent = nullptr);
    ~Profile_page_menu () override;

    public void exec (QPoint &global_position);


    private void on_hovercard_fetched ();
    private void on_icon_loaded (std.size_t &hovercard_action_index);

    private OcsProfileConnector _profile_connector;
    private QMenu _menu;
};


    Profile_page_menu.Profile_page_menu (AccountPointer account, string share_with_user_id, Gtk.Widget parent)
        : Gtk.Widget (parent)
        , _profile_connector (account) {
        connect (&_profile_connector, &OcsProfileConnector.hovercard_fetched, this, &Profile_page_menu.on_hovercard_fetched);
        connect (&_profile_connector, &OcsProfileConnector.icon_loaded, this, &Profile_page_menu.on_icon_loaded);
        _profile_connector.fetch_hovercard (share_with_user_id);
    }

    Profile_page_menu.~Profile_page_menu () = default;

    void Profile_page_menu.exec (QPoint &global_position) {
        _menu.exec (global_position);
    }

    void Profile_page_menu.on_hovercard_fetched () {
        _menu.clear ();

        const var hovercard_actions = _profile_connector.hovercard ()._actions;
        for (var &hovercard_action : hovercard_actions) {
            const var action = _menu.add_action (hovercard_action._icon, hovercard_action._title);
            const var link = hovercard_action._link;
            connect (action, &QAction.triggered, action, [link] (bool) {
                Utility.open_browser (link);
            });
        }
    }

    void Profile_page_menu.on_icon_loaded (std.size_t &hovercard_action_index) {
        const var hovercard_actions = _profile_connector.hovercard ()._actions;
        const var menu_actions = _menu.actions ();
        if (hovercard_action_index >= hovercard_actions.size ()
            || hovercard_action_index >= static_cast<std.size_t> (menu_actions.size ())) {
            return;
        }
        const var menu_action = menu_actions[static_cast<int> (hovercard_action_index)];
        menu_action.set_icon (hovercard_actions[hovercard_action_index]._icon);
    }
    }
    