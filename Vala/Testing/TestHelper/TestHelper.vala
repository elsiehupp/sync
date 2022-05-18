

namespace Occ {
namespace Testing {

public class HttpCredentialsTest : LibSync.HttpCredentials {

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
    public static FolderDefinition folder_definition (string path) {
        FolderDefinition definition;
        definition.local_path = path;
        definition.target_path = path;
        definition.alias = path;
        return definition;
    }

} // class HttpCredentialsTest
} // namespace Testing
} // namespace Occ
