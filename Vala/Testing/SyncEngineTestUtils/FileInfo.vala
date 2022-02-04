/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FileInfo : FileModifier {

    /***********************************************************
    ***********************************************************/
    public static FileInfo A12_B12_C12_S12 ();

    /***********************************************************
    ***********************************************************/
    public FileInfo () = default;
    public FileInfo (string name) : name{name} { }
    public FileInfo (string name, int64 size) : name{name}, isDir{false}, size{size} { }
    public FileInfo (string name, int64 size, char contentChar) : name{name}, isDir{false}, size{size}, contentChar{contentChar} { }
    public FileInfo (string name, std.initializer_list<FileInfo> children);

    /***********************************************************
    ***********************************************************/
    public void addChild (FileInfo info);

    /***********************************************************
    ***********************************************************/
    public void remove (string relativePath) override;

    /***********************************************************
    ***********************************************************/
    public void insert (string relativePath, int64 size = 64, char contentChar = 'W') override;

    /***********************************************************
    ***********************************************************/
    public void setContents (string relativePath, char contentChar) override;

    /***********************************************************
    ***********************************************************/
    public void appendByte (string relativePath) override;

    /***********************************************************
    ***********************************************************/
    public void mkdir (string relativePath) override;

    /***********************************************************
    ***********************************************************/
    public void rename (string oldPath, string newPath) override;

    /***********************************************************
    ***********************************************************/
    public void setModTime (string relativePath, GLib.DateTime modTime) override;

    /***********************************************************
    ***********************************************************/
    public FileInfo find (PathComponents pathComponents, bool invalidateEtags = false);

    /***********************************************************
    ***********************************************************/
    public FileInfo createDir (string relativePath);

    /***********************************************************
    ***********************************************************/
    public FileInfo create (string relativePath, int64 size, char contentChar);

    /***********************************************************
    ***********************************************************/
    public bool operator< (FileInfo other) {
        return name < other.name;
    }


    /***********************************************************
    ***********************************************************/
    public bool operator== (FileInfo other);

    /***********************************************************
    ***********************************************************/
    public bool operator!= (FileInfo other) {
        return !operator== (other);
    }


    /***********************************************************
    ***********************************************************/
    public string path ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string name;
    public int operationStatus = 200;
    public bool isDir = true;
    public bool isShared = false;
    public Occ.RemotePermissions permissions; // When uset, defaults to everything
    public GLib.DateTime lastModified = GLib.DateTime.currentDateTimeUtc ().addDays (-7);


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray etag = generateEtag ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public GLib.ByteArray checksums;
    public GLib.ByteArray extraDavProperties;
    public int64 size = 0;
    public char contentChar = 'W';

    // Sorted by name to be able to compare trees
    public GLib.HashMap<string, FileInfo> children;
    public string parentPath;

    /***********************************************************
    ***********************************************************/
    public FileInfo findInvalidatingEtags (PathComponents pathComponents);

    /***********************************************************
    ***********************************************************/
    public friend inline QDebug operator<< (QDebug dbg, FileInfo& fi) {
        return dbg << "{ " << fi.path () << " : " << fi.children;
    }
}





/***********************************************************
Return the FileInfo for a conflict file for the specified relative filename */
inline const FileInfo findConflict (FileInfo dir, string filename) {
    QFileInfo info (filename);
    const FileInfo parentDir = dir.find (info.path ());
    if (!parentDir)
        return null;
    string on_start = info.baseName () + " (conflicted copy";
    for (var item : parentDir.children) {
        if (item.name.startsWith (on_start)) {
            return item;
        }
    }
    return null;
}