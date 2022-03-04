/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FileInfo : FileModifier {

    /***********************************************************
    ***********************************************************/
    public static FileInfo A12_B12_C12_S12 ();

    /***********************************************************
    ***********************************************************/
    public FileInfo () = default;
    public FileInfo (string name) : name{name} { }
    public FileInfo (string name, int64 size) : name{name}, isDir{false}, size{size} { }
    public FileInfo (string name, int64 size, char content_char) : name{name}, isDir{false}, size{size}, content_char{content_char} { }
    public FileInfo (string name, std.initializer_list<FileInfo> children);

    /***********************************************************
    ***********************************************************/
    public void addChild (FileInfo info);

    /***********************************************************
    ***********************************************************/
    public void remove (string relative_path) override;

    /***********************************************************
    ***********************************************************/
    public void insert (string relative_path, int64 size = 64, char content_char = 'W') override;

    /***********************************************************
    ***********************************************************/
    public void set_contents (string relative_path, char content_char) override;

    /***********************************************************
    ***********************************************************/
    public void append_byte (string relative_path) override;

    /***********************************************************
    ***********************************************************/
    public void mkdir (string relative_path) override;

    /***********************************************************
    ***********************************************************/
    public void rename (string oldPath, string newPath) override;

    /***********************************************************
    ***********************************************************/
    public void set_modification_time (string relative_path, GLib.DateTime modification_time) override;

    /***********************************************************
    ***********************************************************/
    public FileInfo find (PathComponents pathComponents, bool invalidateEtags = false);

    /***********************************************************
    ***********************************************************/
    public FileInfo createDir (string relative_path);

    /***********************************************************
    ***********************************************************/
    public FileInfo create (string relative_path, int64 size, char content_char);

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
    public int operation_status = 200;
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
    public char content_char = 'W';

    // Sorted by name to be able to compare trees
    public GLib.HashMap<string, FileInfo> children;
    public string parentPath;

    /***********************************************************
    ***********************************************************/
    public FileInfo findInvalidatingEtags (PathComponents pathComponents);

    /***********************************************************
    ***********************************************************/
    public friend inline QDebug operator<< (QDebug dbg, FileInfo& fi) {
        return dbg + "{ " + fi.path (" : " + fi.children;
    }
}





/***********************************************************
Return the FileInfo for a conflict file for the specified relative filename */
inline const FileInfo findConflict (FileInfo directory, string filename) {
    GLib.FileInfo info (filename);
    const FileInfo parentDir = directory.find (info.path ());
    if (!parentDir)
        return null;
    string on_signal_start = info.baseName () + " (conflicted copy";
    for (var item : parentDir.children) {
        if (item.name.startsWith (on_signal_start)) {
            return item;
        }
    }
    return null;
}




FileInfo FileInfo.A12_B12_C12_S12 () { { { QStringLiteral ("A"), { { QStringLiteral ("a1"), 4 }, { QStringLiteral ("a2"), 4 } } }, { QStringLiteral ("B"), { { QStringLiteral ("b1"), 16 }, { QStringLiteral ("b2"), 16 } } },
                                  { QStringLiteral ("C"), { { QStringLiteral ("c1"), 24 }, { QStringLiteral ("c2"), 24 } } },
                              } };
    FileInfo sharedFolder { QStringLiteral ("S"), { { QStringLiteral ("s1"), 32 }, { QStringLiteral ("s2"), 32 } } };
    sharedFolder.isShared = true;
    sharedFolder.children[QStringLiteral ("s1")].isShared = true;
    sharedFolder.children[QStringLiteral ("s2")].isShared = true;
    fi.children.insert (sharedFolder.name, std.move (sharedFolder));
    return fi;
}

FileInfo.FileInfo (string name, std.initializer_list<FileInfo> children)
    : name { name } {
    for (var source : children)
        addChild (source);
}

void FileInfo.addChild (FileInfo info) {
    var dest = this.children[info.name] = info;
    dest.parentPath = path ();
    dest.fixupParentPathRecursively ();
}

void FileInfo.remove (string relative_path) {
    const PathComponents pathComponents { relative_path };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    parent.children.erase (std.find_if (parent.children.begin (), parent.children.end (),
        [&pathComponents] (FileInfo fi) { return fi.name == pathComponents.fileName (); }));
}

void FileInfo.insert (string relative_path, int64 size, char content_char) {
    create (relative_path, size, content_char);
}

void FileInfo.set_contents (string relative_path, char content_char) {
    FileInfo file = findInvalidatingEtags (relative_path);
    //  Q_ASSERT (file);
    file.content_char = content_char;
}

void FileInfo.append_byte (string relative_path) {
    FileInfo file = findInvalidatingEtags (relative_path);
    //  Q_ASSERT (file);
    file.size += 1;
}

void FileInfo.mkdir (string relative_path) {
    createDir (relative_path);
}

void FileInfo.rename (string oldPath, string newPath) {
    const PathComponents newPathComponents { newPath };
    FileInfo directory = findInvalidatingEtags (newPathComponents.parentDirComponents ());
    //  Q_ASSERT (directory);
    //  Q_ASSERT (directory.isDir);
    const PathComponents pathComponents { oldPath };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo fi = parent.children.take (pathComponents.fileName ());
    fi.parentPath = directory.path ();
    fi.name = newPathComponents.fileName ();
    fi.fixupParentPathRecursively ();
    directory.children.insert (newPathComponents.fileName (), std.move (fi));
}

void FileInfo.set_modification_time (string relative_path, GLib.DateTime modification_time) {
    FileInfo file = findInvalidatingEtags (relative_path);
    //  Q_ASSERT (file);
    file.lastModified = modification_time;
}

FileInfo *FileInfo.find (PathComponents pathComponents, bool invalidateEtags) {
    if (pathComponents.isEmpty ()) {
        if (invalidateEtags) {
            etag = generateEtag ();
        }
        return this;
    }
    string childName = pathComponents.pathRoot ();
    var it = children.find (childName);
    if (it != children.end ()) {
        var file = it.find (std.move (pathComponents).subComponents (), invalidateEtags);
        if (file && invalidateEtags) {
            // Update parents on the way back
            etag = generateEtag ();
        }
        return file;
    }
    return null;
}

FileInfo *FileInfo.createDir (string relative_path) {
    const PathComponents pathComponents { relative_path };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName ());
    child.parentPath = parent.path ();
    child.etag = generateEtag ();
    return child;
}

FileInfo *FileInfo.create (string relative_path, int64 size, char content_char) {
    const PathComponents pathComponents { relative_path };
    FileInfo parent = findInvalidatingEtags (pathComponents.parentDirComponents ());
    //  Q_ASSERT (parent);
    FileInfo child = parent.children[pathComponents.fileName ()] = FileInfo { pathComponents.fileName (), size };
    child.parentPath = parent.path ();
    child.content_char = content_char;
    child.etag = generateEtag ();
    return child;
}

bool FileInfo.operator== (FileInfo other) {
    // Consider files to be equal between local<.remote as a user would.
    return name == other.name
        && isDir == other.isDir
        && size == other.size
        && content_char == other.content_char
        && children == other.children;
}

string FileInfo.path () {
    return (parentPath.isEmpty () ? "" : (parentPath + '/')) + name;
}

string FileInfo.absolutePath () {
    if (parentPath.endsWith ('/')) {
        return parentPath + name;
    } else {
        return parentPath + '/' + name;
    }
}

void FileInfo.fixupParentPathRecursively () {
    var p = path ();
    for (var it = children.begin (); it != children.end (); ++it) {
        //  Q_ASSERT (it.key () == it.name);
        it.parentPath = p;
        it.fixupParentPathRecursively ();
    }
}

FileInfo *FileInfo.findInvalidatingEtags (PathComponents pathComponents) {
    return find (std.move (pathComponents), true);
}