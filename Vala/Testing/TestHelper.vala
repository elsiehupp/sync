

namespace Testing {

public class HttpCredentialsTest : Occ.HttpCredentials {

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsTest (string user, string password) {
        base (user, password);
    }


    /***********************************************************
    ***********************************************************/
    public override void ask_from_user () {
        return;
    }


    /***********************************************************
    ***********************************************************/
    public static Occ.FolderDefinition folder_definition (string path) {
        Occ.FolderDefinition definition;
        definition.local_path = path;
        definition.target_path = path;
        definition.alias = path;
        return definition;
    }

} // class HttpCredentialsTest
} // namespace Testing
