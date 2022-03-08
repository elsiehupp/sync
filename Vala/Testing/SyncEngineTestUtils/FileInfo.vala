/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FileInfo : FileModifier {

    /***********************************************************
    ***********************************************************/
    public string name;
    public int operation_status = 200;
    public bool isDir = true;
    public bool isShared = false;
    public Occ.RemotePermissions permissions; // When uset, defaults to everything
    public GLib.DateTime last_modified = GLib.DateTime.currentDateTimeUtc ().addDays (-7);

    public GLib.ByteArray checksums;
    public GLib.ByteArray extraDavProperties;
    public int64 size = 0;
    public char content_char = 'W';

    // Sorted by name to be able to compare trees
    public GLib.HashMap<string, FileInfo> children;
    public string parentPath;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray etag = generateEtag ();

    /***********************************************************
    ***********************************************************/
    public FileInfo (string name) {
        this.name = name;
    }


    public FileInfo (string name, int64 size) {
        this.name = name;
        this.isDir = false;
        this.size = size;
    }


    public FileInfo (string name, int64 size, char content_char) {
        this.name = name;
        this.isDir = false;
        this.size = size;
        this.content_char = content_char;
    }


    public FileInfo (string name, std.initializer_list<FileInfo> children) {
        this.name = name;
        foreach (var source in children) {
            add_child (source);
        }
    }

    /***********************************************************
    ***********************************************************/
    public static FileInfo A12_B12_C12_S12 () {
        {
            { QStringLiteral ("A"),
                {
                    { QStringLiteral ("a1"), 4 },
                    { QStringLiteral ("a2"), 4 }
                }
            },
            { QStringLiteral ("B"),
                {
                    { QStringLiteral ("b1"), 16 },
                    { QStringLiteral ("b2"), 16 }
                }
            },
            { QStringLiteral ("C"),
                {
                    { QStringLiteral ("c1"), 24 },
                    { QStringLiteral ("c2"), 24 }
                }
            },
        }
    };
        FileInfo sharedFolder = new FileInfo ( QStringLiteral ("S"), { { QStringLiteral ("s1"), 32 }, { QStringLiteral ("s2"), 32 } } );
        sharedFolder.isShared = true;
        sharedFolder.children[QStringLiteral ("s1")].isShared = true;
        sharedFolder.children[QStringLiteral ("s2")].isShared = true;
        file_info.children.insert (sharedFolder.name, std.move (sharedFolder));
        return file_info;
    }


    /***********************************************************
    ***********************************************************/
    public void add_child (FileInfo info) {
        var dest = this.children[info.name] = info;
        dest.parentPath = path ();
        dest.fixupParentPathRecursively ();
    }


    /***********************************************************
    ***********************************************************/
    public override void remove (string relative_path) {
        const PathComponents path_components ( relative_path };
        FileInfo parent = find_invalidating_etags (path_components.parentDirComponents ());
        //  Q_ASSERT (parent);
        parent.children.erase (std.find_if (parent.children.begin (), parent.children.end (),
            [&path_components] (FileInfo file_info) => {
                return file_info.name == path_components.filename ();
            }
        ));
    }


    /***********************************************************
    ***********************************************************/
    public override void insert (string relative_path, int64 size = 64, char content_char = 'W') {
        create (relative_path, size, content_char);
    }


    /***********************************************************
    ***********************************************************/
    public override void set_contents (string relative_path, char content_char) {
        FileInfo file = find_invalidating_etags (relative_path);
        //  Q_ASSERT (file);
        file.content_char = content_char;
    }


    /***********************************************************
    ***********************************************************/
    public override void append_byte (string relative_path) {
        FileInfo file = find_invalidating_etags (relative_path);
        //  Q_ASSERT (file);
        file.size += 1;
    }


    /***********************************************************
    ***********************************************************/
    public override void mkdir (string relative_path) {
        create_directory (relative_path);
    }


    /***********************************************************
    ***********************************************************/
    public override void rename (string oldPath, string newPath) {
        const PathComponents newPathComponents = new PathComponents (newPath);
        FileInfo directory = find_invalidating_etags (newPathComponents.parentDirComponents ());
        //  Q_ASSERT (directory);
        //  Q_ASSERT (directory.isDir);
        const PathComponents path_components = new PathComponents (oldPath);
        FileInfo parent = find_invalidating_etags (path_components.parentDirComponents ());
        //  Q_ASSERT (parent);
        FileInfo file_info = parent.children.take (path_components.filename ());
        file_info.parentPath = directory.path ();
        file_info.name = newPathComponents.filename ();
        file_info.fixupParentPathRecursively ();
        directory.children.insert (newPathComponents.filename (), std.move (file_info));
    }


    /***********************************************************
    ***********************************************************/
    public override void set_modification_time (string relative_path, GLib.DateTime modification_time) {
        FileInfo file = find_invalidating_etags (relative_path);
        //  Q_ASSERT (file);
        file.last_modified = modification_time;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo find (PathComponents path_components, bool invalidateEtags = false) {
        if (path_components.isEmpty ()) {
            if (invalidateEtags) {
                etag = generateEtag ();
            }
            return this;
        }
        string childName = path_components.pathRoot ();
        var it = children.find (childName);
        if (it != children.end ()) {
            var file = it.find (std.move (path_components).sub_components (), invalidateEtags);
            if (file && invalidateEtags) {
                // Update parents on the way back
                etag = generateEtag ();
            }
            return file;
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo create_directory (string relative_path) {
        const PathComponents path_components = new PathComponents (relative_path);
        FileInfo parent = find_invalidating_etags (path_components.parentDirComponents ());
        //  Q_ASSERT (parent);
        FileInfo child = parent.children[path_components.filename ()] = FileInfo ( path_components.filename ());
        child.parentPath = parent.path ();
        child.etag = generateEtag ();
        return child;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo create (string relative_path, int64 size, char content_char) {
        const PathComponents path_components = new PathComponents (relative_path);
        FileInfo parent = find_invalidating_etags (path_components.parentDirComponents ());
        //  Q_ASSERT (parent);
        FileInfo child = parent.children[path_components.filename ()] = new FileInfo (path_components.filename (), size);
        child.parentPath = parent.path ();
        child.content_char = content_char;
        child.etag = generateEtag ();
        return child;
    }


    /***********************************************************
    ***********************************************************/
    public string path () {
        return (parentPath.isEmpty () ? "" : (parentPath + '/')) + name;
    }


    /***********************************************************
    ***********************************************************/
    public string absolutePath () {
        if (parentPath.endsWith ('/')) {
            return parentPath + name;
        } else {
            return parentPath + '/' + name;
        }
    }

    /***********************************************************
    ***********************************************************/
    public void fixupParentPathRecursively () {
        var p = path ();
        for (var it = children.begin (); it != children.end (); ++it) {
            //  Q_ASSERT (it.key () == it.name);
            it.parentPath = p;
            it.fixupParentPathRecursively ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo find_invalidating_etags (PathComponents path_components) {
        return find (std.move (path_components), true);
    }


    /***********************************************************
    ***********************************************************/
    //  public bool operator< (FileInfo other) {
    //      return name < other.name;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public bool operator== (FileInfo other) {
    //      // Consider files to be equal between local<.remote as a user would.
    //      return name == other.name
    //          && isDir == other.isDir
    //          && size == other.size
    //          && content_char == other.content_char
    //          && children == other.children;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public bool operator!= (FileInfo other) {
    //      return !operator== (other);
    //  }


    /***********************************************************
    ***********************************************************/
    //  public QDebug operator<< (QDebug dbg, FileInfo& file_info) {
    //      return dbg + "{ " + file_info.path (" : " + file_info.children;
    //  }


    /***********************************************************
    Return the FileInfo for a conflict file for the specified
    relative filename
    ***********************************************************/
    FileInfo find_conflict (FileInfo directory, string filename) {
        GLib.FileInfo info = new GLib.FileInfo (filename);
        const FileInfo parentDir = directory.find (info.path ());
        if (!parentDir)
            return null;
        string on_signal_start = info.baseName () + " (conflicted copy";
        foreach (var item in parentDir.children) {
            if (item.name.startsWith (on_signal_start)) {
                return item;
            }
        }
        return null;
    }

} // class FileInfo
} // namespace Testing
