
namespace Occ {
namespace Ui {

public class UserAppsModel { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum UserAppsRoles {
        NAME, // GLib.USER_ROLE + 1,
        URL,
        ICON_URL
    }


    /***********************************************************
    ***********************************************************/
    static UserAppsModel instance {
        public get {
            if (!this.instance) {
                this.instance = new UserAppsModel ();
            }
            return this.instance;
        }
        private set {
            this.instance = value;
        }
    }


    /***********************************************************
    ***********************************************************/
    private GLib.List<AccountApp> apps;


    /***********************************************************
    ***********************************************************/
    private UserAppsModel () {
        //  base ();
    }


    /***********************************************************
    ***********************************************************/
    public void build_app_list () {
        //  if (row_count () > 0) {
        //      begin_remove_rows (GLib.ModelIndex (), 0, row_count () - 1);
        //      this.apps = null;
        //      end_remove_rows ();
        //  }

        //  if (UserModel.instance.app_list.length > 0) {
        //      var talk_app = UserModel.instance.is_current_user ().talk_app ();
        //      foreach (AccountApp app in UserModel.instance.app_list) {
        //          // Filter out Talk because we have a dedicated button for it
        //          if (talk_app && app.identifier == talk_app.identifier)
        //              continue;

        //          begin_insert_rows (GLib.ModelIndex (), row_count (), row_count ());
        //          this.apps + app;
        //          end_insert_rows ();
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private int row_count (GLib.ModelIndex parent) {
        //  //  Q_UNUSED (parent);
        //  return this.apps.length;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Variant data (GLib.ModelIndex index, int role) {
        //  if (index.row () < 0 || index.row () >= this.apps.length) {
        //      return GLib.Variant ();
        //  }

        //  if (role == UserAppsRoles.NAME) {
        //      return this.apps[index.row ()].name ();
        //  } else if (role == UserAppsRoles.URL) {
        //      return this.apps[index.row ()].url;
        //  } else if (role == UserAppsRoles.ICON_URL) {
        //      return this.apps[index.row ()].icon_url ().to_string ();
        //  }
        //  return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_app_url (GLib.Uri url) {
        //  OpenExternal.open_browser (url);
    }

} // class UserAppsModel

} // namespace Ui
} // namespace Occ
