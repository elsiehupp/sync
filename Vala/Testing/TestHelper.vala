

namespace Testing {

class HttpCredentialsTest : Occ.HttpCredentials {

    /***********************************************************
    ***********************************************************/
    public HttpCredentialsTest (string user, string password)
    : HttpCredentials (user, password) {}


    /***********************************************************
    ***********************************************************/
    public void ask_from_user () override {

    }
}

Occ.FolderDefinition folderDefinition (string path);









Occ.FolderDefinition folderDefinition (string path) {
    Occ.FolderDefinition d;
    d.local_path = path;
    d.targetPath = path;
    d.alias = path;
    return d;
}
