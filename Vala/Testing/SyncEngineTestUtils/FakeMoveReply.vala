/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeMoveReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeMoveReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char *, int64) override {
        return 0;
    }

}
}







FakeMoveReply.FakeMoveReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);

    string fileName = get_file_path_from_url (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    string dest = get_file_path_from_url (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
    //  Q_ASSERT (!dest.isEmpty ());
    remote_root_file_info.rename (fileName, dest);
    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

void FakeMoveReply.respond () {
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 201);
    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_finished ();
}