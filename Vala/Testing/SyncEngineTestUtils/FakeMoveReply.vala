/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeMoveReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeMoveReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);

        string filename = get_file_path_from_url (request.url ());
        //  Q_ASSERT (!filename.isEmpty ());
        string dest = get_file_path_from_url (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
        //  Q_ASSERT (!dest.isEmpty ());
        remote_root_file_info.rename (filename, dest);
        QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
    }

    /***********************************************************
    ***********************************************************/
    public void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 201);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        return;
    }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 length) {
        return 0;
    }

} // class FakeMoveReply
} // namespace Testing
