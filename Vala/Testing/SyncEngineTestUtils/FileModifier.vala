/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

abstract class FileModifier {

    /***********************************************************
    ***********************************************************/
    public abstract void remove (string relative_path);

    public abstract void insert (string relative_path, int64 size = 64, char content_char = 'W');

    public abstract void set_contents (string relative_path, char content_char);

    public abstract void append_byte (string relative_path);

    public abstract void mkdir (string relative_path);

    public abstract void rename (string relative_path, string relative_destination_directory);

    public abstract void set_modification_time (string relative_path, GLib.DateTime modification_time);

}
}
