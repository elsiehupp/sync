/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class DiskFileModifier : FileModifier {

    GLib.Dir root_directory;

    /***********************************************************
    ***********************************************************/
    public DiskFileModifier (string root_directory) {
        this.root_directory = root_directory;
    }


    /***********************************************************
    ***********************************************************/
    public override void remove (string relative_path) {
        GLib.FileInfo file_info = new GLib.FileInfo (this.root_directory.file_path (relative_path));
        if (file_info.is_file ()) {
            GLib.assert_true (this.root_directory.remove (relative_path));
        } else {
            GLib.assert_true (GLib.Dir ( file_info.file_path ).remove_recursively ());
        }
    }


    /***********************************************************
    ***********************************************************/
    public override void insert (string relative_path, int64 size = 64, char content_char = 'W') {
        GLib.File file = new GLib.File (this.root_directory.file_path (relative_path));
        GLib.assert_true (!file.exists ());
        file.open (GLib.File.WriteOnly);
        string buffer = string (1024, content_char);
        for (int x = 0; x < size / buffer.size (); ++x) {
            file.write (buffer);
        }
        file.write (buffer, size % buffer.size ());
        file.close ();
        // Set the mtime 30 seconds in the past, for some tests that need to make sure that the mtime differs.
        FileSystem.set_modification_time (file.filename (), Utility.date_time_to_time_t (GLib.DateTime.current_date_time_utc ().add_secs (-30)));
        GLib.assert_true (file.size () == size);
    }


    /***********************************************************
    ***********************************************************/
    public override void set_contents (string relative_path, char content_char) {
        GLib.File file = new GLib.File (this.root_directory.file_path (relative_path));
        GLib.assert_true (file.exists ());
        int64 size = file.size ();
        file.open (GLib.File.WriteOnly);
        file.write ("".fill (content_char, size));
    }


    /***********************************************************
    ***********************************************************/
    public override void append_byte (string relative_path) {
        GLib.File file = new GLib.File (this.root_directory.file_path (relative_path));
        GLib.assert_true (file.exists ());
        file.open (GLib.File.ReadWrite);
        string contents = file.read (1);
        file.seek (file.size ());
        file.write (contents);
    }


    /***********************************************************
    ***********************************************************/
    public override void mkdir (string relative_path) {
        this.root_directory.mkpath (relative_path);
    }


    /***********************************************************
    ***********************************************************/
    public override void rename (string from, string to) {
        GLib.assert_true (this.root_directory.exists (from));
        GLib.assert_true (this.root_directory.rename (from, to));
    }


    /***********************************************************
    ***********************************************************/
    public override void set_modification_time (string relative_path, GLib.DateTime modification_time) {
        FileSystem.set_modification_time (this.root_directory.file_path (relative_path), Utility.date_time_to_time_t (modification_time));
    }

}

} // namespace Testing
} // namespace Occ
