
class HttpCredentialsTest : Occ.HttpCredentials {
public:
    HttpCredentialsTest (QString& user, QString& password)
    : HttpCredentials (user, password) {}

    void askFromUser () override {

    }
};

Occ.FolderDefinition folderDefinition (QString &path);
