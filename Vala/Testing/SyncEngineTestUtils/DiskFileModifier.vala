/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class DiskFileModifier : FileModifier {

    QDir root_directory;

    /***********************************************************
    ***********************************************************/
    public DiskFileModifier (string root_directory) {
        this.root_directory = root_directory;
    }

    /***********************************************************
    ***********************************************************/
    public override void remove (string relative_path) {
        GLib.FileInfo file_info = new GLib.FileInfo (this.root_directory.filePath (relative_path));
        if (file_info.isFile ()) {
            //  QVERIFY (this.root_directory.remove (relative_path));
        } else {
            //  QVERIFY (QDir ( file_info.filePath () ).removeRecursively ());
        }
    }

    /***********************************************************
    ***********************************************************/
    public override void insert (string relative_path, int64 size = 64, char content_char = 'W') {
        GLib.File file = new GLib.File (this.root_directory.filePath (relative_path));
        //  QVERIFY (!file.exists ());
        file.open (GLib.File.WriteOnly);
        GLib.ByteArray buffer = new GLib.ByteArray (1024, content_char);
        for (int x = 0; x < size / buffer.size (); ++x) {
            file.write (buffer);
        }
        file.write (buffer.data (), size % buffer.size ());
        file.close ();
        // Set the mtime 30 seconds in the past, for some tests that need to make sure that the mtime differs.
        Occ.FileSystem.set_modification_time (file.filename (), Occ.Utility.qDateTimeToTime_t (GLib.DateTime.currentDateTimeUtc ().addSecs (-30)));
        //  QCOMPARE (file.size (), size);
    }

    /***********************************************************
    ***********************************************************/
    public override void set_contents (string relative_path, char content_char) {
        GLib.File file = new GLib.File (this.root_directory.filePath (relative_path));
        //  QVERIFY (file.exists ());
        int64 size = file.size ();
        file.open (GLib.File.WriteOnly);
        file.write (GLib.ByteArray ().fill (content_char, size));
    }

    /***********************************************************
    ***********************************************************/
    public override void append_byte (string relative_path) {
        GLib.File file = new GLib.File (this.root_directory.filePath (relative_path));
        //  QVERIFY (file.exists ());
        file.open (GLib.File.ReadWrite);
        GLib.ByteArray contents = file.read (1);
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
        //  QVERIFY (this.root_directory.exists (from));
        //  QVERIFY (this.root_directory.rename (from, to));
    }

    /***********************************************************
    ***********************************************************/
    public override void set_modification_time (string relative_path, GLib.DateTime modification_time) {
        Occ.FileSystem.set_modification_time (this.root_directory.filePath (relative_path), Occ.Utility.qDateTimeToTime_t (modification_time));
    }

}
}
