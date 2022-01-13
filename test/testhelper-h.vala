#ifndef TESTHELPER_H
#define TESTHELPER_H

class HttpCredentialsTest : public OCC.HttpCredentials {
public:
    HttpCredentialsTest (QString& user, QString& password)
    : HttpCredentials (user, password) {}

    void askFromUser () override {

    }
};

OCC.FolderDefinition folderDefinition (QString &path);

#endif // TESTHELPER_H
