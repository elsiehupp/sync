
class HttpCredentialsTest : Occ.HttpCredentials {
public:
    HttpCredentialsTest (string& user, string& password)
    : HttpCredentials (user, password) {}

    void askFromUser () override {

    }
};

Occ.FolderDefinition folderDefinition (string &path);
