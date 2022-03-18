/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FileInfo : FileModifier {

    /***********************************************************
    ***********************************************************/
    public string name;
    public int operation_status = 200;
    public bool is_directory = true;
    public bool is_shared = false;
    public RemotePermissions permissions; // When uset, defaults to everything
    public GLib.DateTime last_modified = GLib.DateTime.current_date_time_utc ().add_days (-7);

    public string checksums;
    public string extra_dav_properties;
    public int64 size = 0;
    public char content_char = 'W';

    // Sorted by name to be able to compare trees
    public GLib.HashTable<string, FileInfo> children;
    public string parent_path;

    /***********************************************************
    ***********************************************************/
    public string etag = generate_etag ();

    /***********************************************************
    ***********************************************************/
    public FileInfo (string name) {
        this.name = name;
    }


    public FileInfo (string name, int64 size) {
        this.name = name;
        this.is_directory = false;
        this.size = size;
    }


    public FileInfo (string name, int64 size, char content_char) {
        this.name = name;
        this.is_directory = false;
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
        var json = {
            {
                "A",
                {
                    {
                        "a1", 4
                    },
                    {
                        "a2", 4
                    }
                }
            },
            {
                "B",
                {
                    {
                        "b1", 16
                    },
                    {
                        "b2", 16
                    }
                }
            },
            {
                "C",
                {
                    {
                        "c1", 24
                    },
                    {
                        "c2", 24
                    }
                }
            },
        };
        FileInfo shared_folder = new FileInfo (
            "S",
            {
                {
                    "s1", 32
                },
                {
                    "s2", 32
                }
            }
        );
        shared_folder.is_shared = true;
        shared_folder.children["s1"].is_shared = true;
        shared_folder.children["s2"].is_shared = true;
        file_info.children.insert (shared_folder.name, std.move (shared_folder));
        return file_info;
    }


    /***********************************************************
    ***********************************************************/
    public void add_child (FileInfo info) {
        var dest = this.children[info.name] = info;
        dest.parent_path = this.path;
        dest.fixup_parent_path_recursively ();
    }


    /***********************************************************
    ***********************************************************/
    public override void remove (string relative_path) {
        const PathComponents path_components = new PathComponents (relative_path);
        FileInfo parent = find_invalidating_etags (path_components.parent_directory_components ());
        GLib.assert_true (parent);
        foreach (var file_info in parent.children) {
            if (file_info.name == path_components.filename ()) {
                parent.children.erase (file_info);
            }
        }
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
        GLib.assert_true (file);
        file.content_char = content_char;
    }


    /***********************************************************
    ***********************************************************/
    public override void append_byte (string relative_path) {
        FileInfo file = find_invalidating_etags (relative_path);
        GLib.assert_true (file);
        file.size += 1;
    }


    /***********************************************************
    ***********************************************************/
    public override void mkdir (string relative_path) {
        create_directory (relative_path);
    }


    /***********************************************************
    ***********************************************************/
    public override void rename (string old_path, string new_path) {
        const PathComponents new_path_components = new PathComponents (new_path);
        FileInfo directory = find_invalidating_etags (new_path_components.parent_directory_components ());
        GLib.assert_true (directory);
        GLib.assert_true (directory.is_directory);
        const PathComponents path_components = new PathComponents (old_path);
        FileInfo parent = find_invalidating_etags (path_components.parent_directory_components ());
        GLib.assert_true (parent);
        FileInfo file_info = parent.children.take (path_components.filename ());
        file_info.parent_path = directory.path;
        file_info.name = new_path_components.filename ();
        file_info.fixup_parent_path_recursively ();
        directory.children.insert (new_path_components.filename (), std.move (file_info));
    }


    /***********************************************************
    ***********************************************************/
    public override void set_modification_time (string relative_path, GLib.DateTime modification_time) {
        FileInfo file = find_invalidating_etags (relative_path);
        GLib.assert_true (file);
        file.last_modified = modification_time;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo find (PathComponents path_components, bool invalidate_etags = false) {
        if (path_components == "") {
            if (invalidate_etags) {
                etag = generate_etag ();
            }
            return this;
        }
        string child_name = path_components.path_root ();
        var it = children.find (child_name);
        if (it != children.end ()) {
            var file = it.find (std.move (path_components).sub_components (), invalidate_etags);
            if (file && invalidate_etags) {
                // Update parents on the way back
                etag = generate_etag ();
            }
            return file;
        }
        return null;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo create_directory (string relative_path) {
        const PathComponents path_components = new PathComponents (relative_path);
        FileInfo parent = find_invalidating_etags (path_components.parent_directory_components ());
        GLib.assert_true (parent);
        FileInfo child = parent.children[path_components.filename ()] = FileInfo ( path_components.filename ());
        child.parent_path = parent.path;
        child.etag = generate_etag ();
        return child;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo create (string relative_path, int64 size, char content_char) {
        const PathComponents path_components = new PathComponents (relative_path);
        FileInfo parent = find_invalidating_etags (path_components.parent_directory_components ());
        GLib.assert_true (parent);
        FileInfo child = parent.children[path_components.filename ()] = new FileInfo (path_components.filename (), size);
        child.parent_path = parent.path;
        child.content_char = content_char;
        child.etag = generate_etag ();
        return child;
    }


    /***********************************************************
    ***********************************************************/
    public string this.path {
        return (parent_path == "" ? "" : (parent_path + "/")) + name;
    }


    /***********************************************************
    ***********************************************************/
    public string absolute_path {
        if (parent_path.ends_with ('/')) {
            return parent_path + name;
        } else {
            return parent_path + '/' + name;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void fixup_parent_path_recursively () {
        var p = this.path;
        for (var it = children.begin (); it != children.end (); ++it) {
            GLib.assert_true (it.key () == it.name);
            it.parent_path = p;
            it.fixup_parent_path_recursively ();
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
    //          && is_directory == other.is_directory
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
    //      return dbg + "{ " + file_info.path (": " + file_info.children;
    //  }


    /***********************************************************
    Return the FileInfo for a conflict file for the specified
    relative filename
    ***********************************************************/
    FileInfo find_conflict (FileInfo directory, string filename) {
        GLib.FileInfo info = new GLib.FileInfo (filename);
        const FileInfo parent_directory = directory.find (info.path);
        if (!parent_directory)
            return null;
        string on_signal_start = info.base_name () + " (conflicted copy";
        foreach (var item in parent_directory.children) {
            if (item.name.starts_with (on_signal_start)) {
                return item;
            }
        }
        return null;
    }

} // class FileInfo
} // namespace Testing
} // namespace Occ
