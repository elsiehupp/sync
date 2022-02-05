
class User_apps_model : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public static User_apps_model instance ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public enum User_apps_roles {
        Name_role = Qt.User_role + 1,
        Url_role,
        Icon_url_role
    }

    /***********************************************************
    ***********************************************************/
    public void build_app_list ();

    /***********************************************************
    ***********************************************************/
    public void on_open_app_url (GLib.Uri url);


    protected GLib.HashMap<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private static User_apps_model this.instance;

    /***********************************************************
    ***********************************************************/
    private 
    private AccountAppList this.apps;
}




User_apps_model *User_apps_model.instance = null;

User_apps_model *User_apps_model.instance () {
    if (!this.instance) {
        this.instance = new User_apps_model ();
    }
    return this.instance;
}

User_apps_model.User_apps_model (GLib.Object parent)
    : QAbstractListModel (parent) {
}

void User_apps_model.build_app_list () {
    if (row_count () > 0) {
        begin_remove_rows (QModelIndex (), 0, row_count () - 1);
        this.apps.clear ();
        end_remove_rows ();
    }

    if (User_model.instance ().app_list ().count () > 0) {
        const var talk_app = User_model.instance ().current_user ().talk_app ();
        foreach (AccountApp app, User_model.instance ().app_list ()) {
            // Filter out Talk because we have a dedicated button for it
            if (talk_app && app.identifier () == talk_app.identifier ())
                continue;

            begin_insert_rows (QModelIndex (), row_count (), row_count ());
            this.apps << app;
            end_insert_rows ();
        }
    }
}

void User_apps_model.on_open_app_url (GLib.Uri url) {
    Utility.open_browser (url);
}

int User_apps_model.row_count (QModelIndex parent) {
    //  Q_UNUSED (parent);
    return this.apps.count ();
}

GLib.Variant User_apps_model.data (QModelIndex index, int role) {
    if (index.row () < 0 || index.row () >= this.apps.count ()) {
        return GLib.Variant ();
    }

    if (role == Name_role) {
        return this.apps[index.row ()].name ();
    } else if (role == Url_role) {
        return this.apps[index.row ()].url ();
    } else if (role == Icon_url_role) {
        return this.apps[index.row ()].icon_url ().to_string ();
    }
    return GLib.Variant ();
}

GLib.HashMap<int, GLib.ByteArray> User_apps_model.role_names () {
    GLib.HashMap<int, GLib.ByteArray> roles;
    roles[Name_role] = "app_name";
    roles[Url_role] = "app_url";
    roles[Icon_url_role] = "app_icon_url";
    return roles;
}