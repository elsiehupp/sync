/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class DiskFileModifier : FileModifier {
    QDir this.rootDir;

    /***********************************************************
    ***********************************************************/
    public DiskFileModifier (string rootDirPath) : this.rootDir (rootDirPath) { }
    public void remove (string relativePath) override;
    public void insert (string relativePath, int64 size = 64, char contentChar = 'W') override;
    public void setContents (string relativePath, char contentChar) override;
    public void appendByte (string relativePath) override;

    /***********************************************************
    ***********************************************************/
    public void mkdir (string relativePath) override;
    public void rename (string from, string to) override;
    public void setModTime (string relativePath, GLib.DateTime modTime) override;
};