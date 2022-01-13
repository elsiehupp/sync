
Occ.FolderDefinition folderDefinition (string &path) {
    Occ.FolderDefinition d;
    d.localPath = path;
    d.targetPath = path;
    d.alias = path;
    return d;
}
