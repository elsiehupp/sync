/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeMkcolReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakeMkcolReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent);

    public void respond ();

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () { }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *, int64) {
        return 0;
    }

}
}




FakeMkcolReply.FakeMkcolReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);

    string fileName = get_file_path_from_url (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    file_info = remote_root_file_info.createDir (fileName);

    if (!file_info) {
        on_signal_abort ();
        return;
    }
    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

void FakeMkcolReply.respond () {
    setRawHeader ("OC-FileId", file_info.file_identifier);
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 201);
    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_finished ();
}