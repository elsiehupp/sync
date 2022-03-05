/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakePutReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakePutReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.ByteArray putPayload, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray putPayload);

    /***********************************************************
    ***********************************************************/
    public virtual void respond ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char *, int64) override {
        return 0;
    }

}
}








FakePutReply.FakePutReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.ByteArray putPayload, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);
    file_info = perform (remote_root_file_info, request, putPayload);
    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

FileInfo *FakePutReply.perform (FileInfo remote_root_file_info, Soup.Request request, GLib.ByteArray putPayload) {
    string fileName = get_file_path_from_url (request.url ());
    //  Q_ASSERT (!fileName.isEmpty ());
    FileInfo file_info = remote_root_file_info.find (fileName);
    if (file_info) {
        file_info.size = putPayload.size ();
        file_info.content_char = putPayload.at (0);
    } else {
        // Assume that the file is filled with the same character
        file_info = remote_root_file_info.create (fileName, putPayload.size (), putPayload.at (0));
    }
    file_info.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
    remote_root_file_info.find (fileName, /*invalidateEtags=*/true);
    return file_info;
}

void FakePutReply.respond () {
    /* emit */ uploadProgress (file_info.size, file_info.size);
    setRawHeader ("OC-ETag", file_info.etag);
    setRawHeader ("ETag", file_info.etag);
    setRawHeader ("OC-FileID", file_info.file_identifier);
    setRawHeader ("X-OC-MTime", "accepted"); // Prevents Q_ASSERT (!this.runningNow) since we'll call PropagateItemJob.done twice in that case.
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 200);
    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_finished ();
}

void FakePutReply.on_signal_abort () {
    set_error (OperationCanceledError, "on_signal_abort");
    /* emit */ signal_finished ();
}