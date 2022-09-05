

//  #include <GLib.Box_layout>
//  #include <account.h>
//  #include <GLib.Menu>
//  #include <cstddef>

namespace Occ {
namespace Ui {

public class ProfilePageMenu { //: Gtk.Widget {

    //  /***********************************************************
    //  ***********************************************************/
    //  private OcsProfileConnector profile_connector;
    //  private GLib.Menu menu;

    //  /***********************************************************
    //  ***********************************************************/
    //  public ProfilePageMenu (LibSync.Account account, string share_with_user_id, Gtk.Widget parent = new Gtk.Widget ()) {
    //      base (parent);
    //      this.profile_connector = account;
    //      this.profile_connector.hovercard_fetched.connect (
    //          this.on_signal_hovercard_fetched
    //      );
    //      this.profile_connector.signal_icon_loaded.connect (
    //          this.on_signal_icon_loaded
    //      );
    //      this.profile_connector.fetch_hovercard (share_with_user_id);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void exec (GLib.Point global_position) {
    //      this.menu.exec (global_position);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_hovercard_fetched () {
    //      this.menu == new GLib.Menu ();

    //      GLib.List<HovercardAction> hovercard_actions = this.profile_connector.current_hovercard.actions;
    //      foreach (var hovercard_action in hovercard_actions) {
    //          var action = this.menu.add_action (hovercard_action.icon, hovercard_action.title);
    //          var link = hovercard_action.link;
    //          action.triggered.connect (
    //              action.on_signal_hovercard_open_browser
    //          );
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private static void on_signal_hovercard_open_browser (string link) {
    //      OpenExternal.open_browser (link);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_icon_loaded (size_t hovercard_action_index) {
    //      GLib.List<HovercardAction> hovercard_actions = this.profile_connector.current_hovercard.actions;
    //      var menu_actions = this.menu.actions ();
    //      if (hovercard_action_index >= hovercard_actions.size ()
    //          || hovercard_action_index >= (size_t)menu_actions.size ()) {
    //          return;
    //      }
    //      var menu_action = menu_actions[(int)hovercard_action_index];
    //      menu_action.icon (hovercard_actions[hovercard_action_index].icon);
    //  }

} // class ProfilePageMenu

} // namespace Ui
} // namespace Occ
