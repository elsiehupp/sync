
namespace Occ {
namespace Ui {

class UserAppsModel : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public enum UserAppsRoles {
        NAME = Qt.USER_ROLE + 1,
        URL,
        ICON_URL;

        internal GLib.HashMap<int, GLib.ByteArray> role_names () {
            GLib.HashMap<int, GLib.ByteArray> roles;
            roles[UserAppsRoles.NAME] = "app_name";
            roles[UserAppsRoles.URL] = "app_url";
            roles[UserAppsRoles.ICON_URL] = "app_icon_url";
            return roles;
        }
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
    private AccountAppList apps;


    /***********************************************************
    ***********************************************************/
    private UserAppsModel (GLib.Object parent) {
        base (parent);
    }

    /***********************************************************
    ***********************************************************/
    public 


    /***********************************************************
    ***********************************************************/
    public void build_app_list () {
        if (row_count () > 0) {
            begin_remove_rows (QModelIndex (), 0, row_count () - 1);
            this.apps.clear ();
            end_remove_rows ();
        }

        if (UserModel.instance ().app_list ().count () > 0) {
            const var talk_app = UserModel.instance ().is_current_user ().talk_app ();
            foreach (AccountApp app, UserModel.instance ().app_list ()) {
                // Filter out Talk because we have a dedicated button for it
                if (talk_app && app.identifier () == talk_app.identifier ())
                    continue;

                begin_insert_rows (QModelIndex (), row_count (), row_count ());
                this.apps + app;
                end_insert_rows ();
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private int row_count (QModelIndex parent) {
        //  Q_UNUSED (parent);
        return this.apps.count ();
    }


    /***********************************************************
    ***********************************************************/
    private GLib.Variant data (QModelIndex index, int role) {
        if (index.row () < 0 || index.row () >= this.apps.count ()) {
            return GLib.Variant ();
        }

        if (role == UserAppsRoles.NAME) {
            return this.apps[index.row ()].name ();
        } else if (role == UserAppsRoles.URL) {
            return this.apps[index.row ()].url ();
        } else if (role == UserAppsRoles.ICON_URL) {
            return this.apps[index.row ()].icon_url ().to_string ();
        }
        return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_open_app_url (GLib.Uri url) {
        Utility.open_browser (url);
    }

} // class UserAppsModel

} // namespace Ui
} // namespace Occ