

//  #include <QBox_layout>
//  #include <account.h>
//  #include <QMenu>
//  #include <cstddef>

namespace Occ {
namespace Ui {

public class ProfilePageMenu : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private OcsProfileConnector profile_connector;
    private QMenu menu;

    /***********************************************************
    ***********************************************************/
    public ProfilePageMenu (unowned Account account, string share_with_user_id, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.profile_connector = account;
        connect (this.profile_connector, OcsProfileConnector.hovercard_fetched, this, ProfilePageMenu.on_signal_hovercard_fetched);
        connect (this.profile_connector, OcsProfileConnector.icon_loaded, this, ProfilePageMenu.on_signal_icon_loaded);
        this.profile_connector.fetch_hovercard (share_with_user_id);
    }


    /***********************************************************
    ***********************************************************/
    public void exec (QPoint global_position) {
        this.menu.exec (global_position);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_hovercard_fetched () {
        this.menu.clear ();

        const var hovercard_actions = this.profile_connector.hovercard ().actions;
        foreach (var hovercard_action in hovercard_actions) {
            const var action = this.menu.add_action (hovercard_action.icon, hovercard_action.title);
            const var link = hovercard_action.link;
            connect (
                action,
                QAction.triggered,
                action,
                this.on_signal_hovercard_open_browser);
        }
    }


    /***********************************************************
    ***********************************************************/
    private static void on_signal_hovercard_open_browser (string link) {
        Utility.open_browser (link);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_icon_loaded (size_t hovercard_action_index) {
        const var hovercard_actions = this.profile_connector.hovercard ().actions;
        const var menu_actions = this.menu.actions ();
        if (hovercard_action_index >= hovercard_actions.size ()
            || hovercard_action_index >= static_cast<size_t> (menu_actions.size ())) {
            return;
        }
        const var menu_action = menu_actions[static_cast<int> (hovercard_action_index)];
        menu_action.icon (hovercard_actions[hovercard_action_index].icon);
    }

} // class ProfilePageMenu

} // namespace Ui
} // namespace Occ
