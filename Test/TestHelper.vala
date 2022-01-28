
class HttpCredentialsTest : Occ.HttpCredentials {

    public HttpCredentialsTest (string& user, string& password)
    : HttpCredentials (user, password) {}


    public void askFromUser () override {

    }
};

Occ.FolderDefinition folderDefinition (string path);









Occ.FolderDefinition folderDefinition (string path) {
    Occ.FolderDefinition d;
    d.localPath = path;
    d.targetPath = path;
    d.alias = path;
    return d;
}
