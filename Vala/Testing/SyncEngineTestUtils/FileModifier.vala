/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FileModifier {

    /***********************************************************
    ***********************************************************/
    public virtual ~FileModifier () = default;
    public virtual void remove (string relative_path);
    public virtual void insert (string relative_path, int64 size = 64, char content_char = 'W');
    public virtual void set_contents (string relative_path, char content_char);
    public virtual void append_byte (string relative_path);
    public virtual void mkdir (string relative_path);
    public virtual void rename (string relative_path, string relativeDestinationDirectory);
    public virtual void set_modification_time (string relative_path, GLib.DateTime modification_time);
};