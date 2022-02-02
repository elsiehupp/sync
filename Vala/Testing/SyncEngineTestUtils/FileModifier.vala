/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FileModifier {

    /***********************************************************
    ***********************************************************/
    public virtual ~FileModifier () = default;
    public virtual void remove (string relativePath);
    public virtual void insert (string relativePath, int64 size = 64, char contentChar = 'W');
    public virtual void setContents (string relativePath, char contentChar);
    public virtual void appendByte (string relativePath);
    public virtual void mkdir (string relativePath);
    public virtual void rename (string relativePath, string relativeDestinationDirectory);
    public virtual void setModTime (string relativePath, GLib.DateTime modTime);
};