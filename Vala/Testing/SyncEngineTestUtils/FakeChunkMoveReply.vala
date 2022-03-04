
namespace Testing {

class FakeChunkMoveReply : FakeReply {

    FileInfo file_info;

    /***********************************************************
    ***********************************************************/
    public FakeChunkMoveReply (FileInfo uploads_file_info, FileInfo remote_root_file_info,
        QNetworkAccessManager.Operation operation, Soup.Request request,
        GLib.Object parent) {
        base (parent);
        setRequest (request);
        setUrl (request.url ());
        setOperation (operation);
        open (QIODevice.ReadOnly);
        file_info = perform (uploads_file_info, remote_root_file_info, request);
        if (!file_info) {
            QTimer.singleShot (0, this, &FakeChunkMoveReply.respondPreconditionFailed);
        } else {
            QTimer.singleShot (0, this, &FakeChunkMoveReply.respond);
        }
    }

    /***********************************************************
    ***********************************************************/
    public static FileInfo perform (FileInfo uploads_file_info, FileInfo remote_root_file_info, Soup.Request request);
    FileInfo *FakeChunkMoveReply.perform (FileInfo uploads_file_info, FileInfo remote_root_file_info, Soup.Request request) {
        string source = getFilePathFromUrl (request.url ());
        //  Q_ASSERT (!source.isEmpty ());
        //  Q_ASSERT (source.endsWith (QLatin1String ("/.file")));
        source = source.left (source.length () - static_cast<int> (qstrlen ("/.file")));

        var sourceFolder = uploads_file_info.find (source);
        //  Q_ASSERT (sourceFolder);
        //  Q_ASSERT (sourceFolder.isDir);
        int count = 0;
        int64 size = 0;
        char payload = '\0';

        string fileName = getFilePathFromUrl (GLib.Uri.fromEncoded (request.rawHeader ("Destination")));
        //  Q_ASSERT (!fileName.isEmpty ());

        // Compute the size and content from the chunks if possible
        for (var chunkName : sourceFolder.children.keys ()) {
            var x = sourceFolder.children[chunkName];
            //  Q_ASSERT (!x.isDir);
            //  Q_ASSERT (x.size > 0); // There should not be empty chunks
            size += x.size;
            //  Q_ASSERT (!payload || payload == x.content_char);
            payload = x.content_char;
            ++count;
        }
        //  Q_ASSERT (sourceFolder.children.count () == count); // There should not be holes or extra files

        // Note: This does not actually assemble the file data from the chunks!
        FileInfo file_info = remote_root_file_info.find (fileName);
        if (file_info) {
            // The client should put this header
            //  Q_ASSERT (request.hasRawHeader ("If"));

            // And it should condition on the destination file
            var on_signal_start = GLib.ByteArray ("<" + request.rawHeader ("Destination") + ">");
            //  Q_ASSERT (request.rawHeader ("If").startsWith (on_signal_start));

            if (request.rawHeader ("If") != on_signal_start + " ([\"" + file_info.etag + "\"])") {
                return null;
            }
            file_info.size = size;
            file_info.content_char = payload;
        } else {
            //  Q_ASSERT (!request.hasRawHeader ("If"));
            // Assume that the file is filled with the same character
            file_info = remote_root_file_info.create (fileName, size, payload);
        }
        file_info.lastModified = Occ.Utility.qDateTimeFromTime_t (request.rawHeader ("X-OC-Mtime").toLongLong ());
        remote_root_file_info.find (fileName, /*invalidateEtags=*/true);

        return file_info;
    }

    /***********************************************************
    ***********************************************************/
    public virtual void respond () {
        setAttribute (Soup.Request.HttpStatusCodeAttribute, 201);
        setRawHeader ("OC-ETag", file_info.etag);
        setRawHeader ("ETag", file_info.etag);
        setRawHeader ("OC-FileId", file_info.file_identifier);
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
    }

    /***********************************************************
    ***********************************************************/
    public void respondPreconditionFailed () {
        setAttribute (Soup.Request.HttpStatusCodeAttribute, 412);
        setError (InternalServerError, "Precondition Failed");
        /* emit */ metaDataChanged ();
        /* emit */ finished ();
    }

    /***********************************************************
    ***********************************************************/
    public override void on_signal_abort () {
        setError (OperationCanceledError, "on_signal_abort");
        /* emit */ finished ();
    }

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char *, int64) override {
        return 0;
    }

}
}
