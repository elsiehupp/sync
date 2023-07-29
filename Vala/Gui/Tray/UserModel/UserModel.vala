
//  #include <Gtk.Image>
//  #include <GLib.QuickImageProvider>
//  #include <chrono>
//  #include <pushnotifications
//  #include <GLib.DesktopServ
//  #include <Gtk.IconInfo>
//  #include <GLib.MessageB
//  #include <GLib.SvgRenderer>
//  #include <GLib.Painter>
//  #include <GLib.PushButton>

namespace Occ {
namespace Ui {

public class UserModel { //: GLib.Object {

    public enum UserRoles {
        NAME, // GLib.USER_ROLE + 1,
        SERVER,
        SERVER_HAS_USER_STATUS,
        STATUS_ICON,
        STATUS_EMOJI,
        STATUS_MESSAGE,
        DESKTOP_NOTIFICATION,
        AVATAR,
        IS_CURRENT_USER,
        IS_CONNECTED,
        IDENTIFIER
    }


    /***********************************************************
    ***********************************************************/
    public static UserModel instance {
        public get {
            if (UserModel.instance == null) {
                UserModel.instance = new UserModel ();
            }
            return UserModel.instance;
        }
        private set {
            UserModel.instance = value;
        }
    }


    private GLib.List<User> users;


    /***********************************************************
    ***********************************************************/
    public int current_user_id {
        public get {
            return this.current_user_id;
        }
        private set {
            this.current_user_id = value;
        }
        //  construct {
        //      this.current_user_id = 0;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public static User current_user {
        public get {
            if (UserModel.current_user_id < 0 || UserModel.current_user_id >= UserModel.users.length ()) {
                return null;
            }
            return UserModel.users[this.current_user_id];
        }
    }


    /***********************************************************
    ***********************************************************/
    public string current_user_server {
        public get {
            if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
                return "";
            }
            return this.users[this.current_user_id].server;
        }
    }


    /***********************************************************
    ***********************************************************/
    public int number_of_users {
        public get {
            return this.users.size ();
        }
    }

    private bool init = true;


    internal signal void signal_add_account ();
    internal signal void signal_new_user_selected ();


    /***********************************************************
    ***********************************************************/
    private UserModel () {
        //  base ();
        //  // TODO: Remember selected user from last quit via settings file
        //  if (AccountManager.instance.accounts.size () > 0) {
        //      build_user_list ();
        //  }

        //  AccountManager.instance.signal_account_added.connect (
        //      this.on_signal_build_user_list
        //  );
    }


    /***********************************************************
    ***********************************************************/
    public bool is_user_connected (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ())
        //      return false;

        //  return this.users[identifier].is_connected;
    }


    /***********************************************************
    ***********************************************************/
    public int row_count (GLib.ModelIndex index = GLib.ModelIndex ()) {
        //  //  Q_UNUSED (index);
        //  return this.users.length;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (int index, int role) {
        //  if (index < 0 || index >= this.users.length) {
        //      return null;
        //  }

        //  if (role == UserRoles.NAME) {
        //      return new GLib.Variant.string (this.users.nth_data (index).name);
        //  } else if (role == UserRoles.SERVER) {
        //      return new GLib.Variant.string (this.users.nth_data (index).server);
        //  } else if (role == UserRoles.SERVER_HAS_USER_STATUS) {
        //      return new GLib.Variant.boolean (this.users.nth_data (index).server_has_user_status);
        //  } else if (role == UserRoles.STATUS_ICON) {
        //      return new GLib.Variant.string (this.users.nth_data (index).status_icon);
        //  } else if (role == UserRoles.STATUS_EMOJI) {
        //      return new GLib.Variant.string (this.users.nth_data (index).status_emoji);
        //  } else if (role == UserRoles.STATUS_MESSAGE) {
        //      return new GLib.Variant.string (this.users.nth_data (index).status_message);
        //  } else if (role == UserRoles.DESKTOP_NOTIFICATION) {
        //      return new GLib.Variant.boolean (this.users.nth_data (index).are_desktop_notifications_allowed);
        //  } else if (role == UserRoles.AVATAR) {
        //      return new GLib.Variant.string (this.users.nth_data (index).avatar_url);
        //  } else if (role == UserRoles.IS_CURRENT_USER) {
        //      return new GLib.Variant.boolean (this.users.nth_data (index).is_current_user);
        //  } else if (role == UserRoles.IS_CONNECTED) {
        //      return new GLib.Variant.boolean (this.users.nth_data (index).is_connected);
        //  } else if (role == UserRoles.IDENTIFIER) {
        //      return index;
        //  }
        //  return new GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image avatar_by_identifier (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ())
        //      return null;

        //  return this.users[identifier].avatar ();
    }


    /***********************************************************
    ***********************************************************/
    public int find_identifier_for_account (AccountState account_state) {
        //  int identifier = 0;
        //  foreach (var user in this.users) {
        //      identifer++;
        //      if (user.account.identifier == account_state.account.identifier) {
        //          break;
        //      }
        //  }
        //  if (identifier == this.users.length) {
        //      identifier =-1;
        //  }
        //  return identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_current_activity_model () {
        //  if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
        //      return;
        //  }

        //  this.users[this.current_user_id].on_signal_refresh ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_user (AccountState account_state, bool is_current) {
        //  bool contains_user = false;
        //  foreach (var user in this.users) {
        //      if (user.account == account_state.account) {
        //          contains_user = true;
        //          continue;
        //      }
        //  }

        //  if (!contains_user) {
        //      int row = row_count ();
        //      begin_insert_rows (GLib.ModelIndex (), row, row);

        //      User new_user = new User (account_state, is_current);

        //      new_user.signal_avatar_changed.connect (
        //          this.on_signal_avatar_changed
        //      );

        //      new_user.signal_status_changed.connect (
        //          this.on_signal_status_changed
        //      );

        //      new_user.signal_desktop_notifications_allowed_changed.connect (
        //          this.on_signal_desktop_notifications_allowed_changed
        //      );

        //      new_user.signal_account_state_changed.connect (
        //          this.on_signal_account_state_changed
        //      );

        //      this.users += new_user;

        //      if (is_current) {
        //          this.current_user_id = this.users.index_of (this.users.last ());
        //      }

        //      end_insert_rows ();
        //      LibSync.ConfigFile config;
        //      this.users.last ().on_signal_notification_refresh_interval (config.notification_refresh_interval ());
        //      signal_new_user_selected ();
        //  }
    }



    /***********************************************************
    ***********************************************************/
    private void on_signal_avatar_changed (int row) {
        //  signal_data_changed (
        //      index (row, 0),
        //      index (row, 0),
        //      {
        //          UserModel.UserRoles.AVATAR
        //      }
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_status_changed (int row) {
        //  signal_data_changed (
        //      index (row, 0),
        //      index (row, 0),
        //      {
        //          UserModel.UserRoles.STATUS_ICON,
        //          UserModel.UserRoles.STATUS_EMOJI,
        //          UserModel.UserRoles.STATUS_MESSAGE
        //      }
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_desktop_notifications_allowed_changed (int row) {
        //  signal_data_changed (
        //      index (row, 0),
        //      index (row, 0),
        //      {
        //          UserModel.UserRoles.DESKTOP_NOTIFICATION
        //      }
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_state_changed (int row) {
        //  signal_data_changed (
        //      index (row, 0),
        //      index (row, 0),
        //      {
        //          UserModel.UserRoles.IS_CONNECTED
        //      }
        //  );
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_local_folder () {
        //  if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
        //      return;
        //  }

        //  this.users[this.current_user_id].open_local_folder ();
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_talk () {
        //  if (UserModel.current_user == null) {
        //      return;
        //  }

        //  var talk_app = UserModel.current_user.talk_app ();
        //  if (talk_app) {
        //      OpenExternal.open_browser (talk_app.url);
        //  } else {
        //      GLib.warning ("The Talk app is not enabled on " + this.current_user.server ());
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_server () {
        //  if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
        //      return;
        //  }

        //  string url = this.users[this.current_user_id].server (false);
        //  if (!url.has_prefix ("http://") && !url.has_prefix ("https://")) {
        //      url = "https://" + this.users[this.current_user_id].server (false);
        //  }

        //  GLib.DesktopServices.open_url (url);
    }


    /***********************************************************
    ***********************************************************/
    public void switch_current_user (int identifier) {
        //  if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
        //      return;
        //  }

        //  this.users[this.current_user_id].is_current_user (false);
        //  this.users[identifier].is_current_user (true);
        //  this.current_user_id = identifier;
        //  signal_new_user_selected ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_in (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ()) {
        //      return;
        //  }

        //  this.users[identifier].log_in ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_out (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ()) {
        //      return;
        //  }

        //  this.users[identifier].log_out ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_account (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ())
        //      return;

        //  Gtk.MessageBox message_box = new Gtk.MessageBox (
        //      Gtk.MessageBox.Question,
        //      _("Confirm LibSync.Account Removal"),
        //      _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
        //      + "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
        //          .printf (this.users[identifier].name ()),
        //      Gtk.MessageBox.NoButton);
        //  GLib.PushButton yes_button =
        //      message_box.add_button (_("Remove connection"), Gtk.MessageBox.YesRole);
        //  message_box.add_button (_("Cancel"), Gtk.MessageBox.NoRole);

        //  message_box.exec ();
        //  if (message_box.clicked_button () != yes_button) {
        //      return;
        //  }

        //  if (this.users[identifier].is_current_user () && this.users.length > 1) {
        //      if (identifier == 0) {
        //          switch_current_user (1);
        //      } else {
        //          switch_current_user (0);
        //      }
        //  }

        //  this.users[identifier].log_out ();
        //  this.users[identifier].remove_account ();

        //  begin_remove_rows (GLib.ModelIndex (), identifier, identifier);
        //  this.users.remove_at (identifier);
        //  end_remove_rows ();
    }


    /***********************************************************
    ***********************************************************/
    public AbstractUserStatusConnector user_status_connector (int identifier) {
        //  if (identifier < 0 || identifier >= this.users.size ()) {
        //      return null;
        //  }

        //  return this.users[identifier].account.user_status_connector ();
    }


    /***********************************************************
    ***********************************************************/
    public ActivityListModel current_activity_model {
        public get {
            if (current_user_id < 0 || current_user_id >= this.users.size ()) {
                return null;
            }
            return this.users[current_user_id].activity_model ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<AccountApp> app_list {
        public get {
            if (this.current_user_id < 0 || this.current_user_id >= this.users.length ()) {
                return null;
            }
            return new GLib.Variant (this.users.nth_data (this.current_user_id).app_list);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void build_user_list () {
        //  for (int i = 0; i < AccountManager.instance.accounts.size (); i++) {
        //      var user = AccountManager.instance.accounts.at (i);
        //      add_user (user);
        //  }
        //  if (this.init) {
        //      this.users.nth_data (0).is_current_user (true);
        //      this.init = false;
        //  }
    }

} // class UserModel

} // namespace Ui
} // namespace Occ
