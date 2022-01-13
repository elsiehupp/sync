
OCC::FolderDefinition folderDefinition(QString &path) {
    OCC::FolderDefinition d;
    d.localPath = path;
    d.targetPath = path;
    d.alias = path;
    return d;
}
