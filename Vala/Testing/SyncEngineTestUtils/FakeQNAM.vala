/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeQNAM : Soup {

    /***********************************************************
    ***********************************************************/
    private FileInfo remote_root_file_info;

    /***********************************************************
    ***********************************************************/
    private FileInfo upload_file_info;

    /***********************************************************
    Maps a path to an HTTP error
    ***********************************************************/
    private GLib.HashMap<string, int> error_paths;

    /***********************************************************
    Monitor requests and optionally provide custom replies
    ***********************************************************/
    private Override override_value;

    /***********************************************************
    ***********************************************************/
    public delegate Soup.Reply Override (Operation value1, Soup.Request value2, QIODevice value3);

    /***********************************************************
    ***********************************************************/
    public FakeQNAM (FileInfo initialRoot) {
        this.remote_root_file_info = std.move (initialRoot);
        setCookieJar (new Occ.CookieJar ());
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo current_remote_state () {
        return this.remote_root_file_info;
    }


    /***********************************************************
    ***********************************************************/
    public FileInfo upload_state () {
        return this.upload_file_info;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.HashMap<string, int> error_paths () {
        return this.error_paths;
    }


    /***********************************************************
    ***********************************************************/
    public QJsonObject for_each_reply_part (
        QIODevice outgoing_data,
        string content_type,
        std.function<QJsonObject (GLib.HashMap<string, GLib.ByteArray> &)> reply_function) {
        var fullReply = new QJsonObject ();
        var putPayload = outgoing_data.peek (outgoing_data.bytes_available ());
        outgoing_data.on_signal_reset ();
        var stringPutPayload = string.fromUtf8 (putPayload);
        const int boundaryPosition = sizeof ("multipart/related; boundary=");
        const string boundaryValue = QStringLiteral ("--") + content_type.mid (boundaryPosition, content_type.length () - boundaryPosition - 1) + QStringLiteral ("\r\n");
        var stringPutPayloadRef = string{stringPutPayload}.left (stringPutPayload.size () - 2 - boundaryValue.size ());
        var allParts = stringPutPayloadRef.split (boundaryValue, Qt.SkipEmptyParts);
        for (var onePart : qAsConst (allParts)) {
            var headerEndPosition = onePart.indexOf (QStringLiteral ("\r\n\r\n"));
            var onePartHeaderPart = onePart.left (headerEndPosition);
            var onePartHeaders = onePartHeaderPart.split (QStringLiteral ("\r\n"));
            GLib.HashMap<string, GLib.ByteArray> allHeaders;
            for (var oneHeader : qAsConst (onePartHeaders)) {
                var headerParts = oneHeader.split (QStringLiteral (" : "));
                allHeaders[headerParts.at (0)] = headerParts.at (1).toLatin1 ();
            }

            var reply = reply_function (allHeaders);
            if (reply.contains (QStringLiteral ("error")) &&
                    reply.contains (QStringLiteral ("etag"))) {
                fullReply.insert (allHeaders[QStringLiteral ("X-File-Path")], reply);
            }
        }

        return fullReply;
    }

    /***********************************************************
    ***********************************************************/
    public Soup.Reply overrideReplyWithError (string fileName, Operation operation, Soup.Request newRequest) {
        Soup.Reply reply = null;

        //  Q_ASSERT (!fileName.isNull ());
        if (this.error_paths.contains (fileName)) {
            reply = new FakeErrorReply ( operation, newRequest, this, this.error_paths[fileName] };
        }

        return reply;
    }


    /***********************************************************
    ***********************************************************/
    protected override Soup.Reply createRequest (Operation operation, Soup.Request request,
        QIODevice outgoing_data = null) {
        Soup.Reply reply = null;
        var newRequest = request;
        newRequest.set_raw_header ("X-Request-ID", Occ.AccessManager.generateRequestId ());
        var content_type = request.header (Soup.Request.ContentTypeHeader).toString ();
        if (this.override_value) {
            if (var this.reply = this.override_value (operation, newRequest, outgoing_data)) {
                reply = this.reply;
            }
        }
        if (!reply) {
            reply = overrideReplyWithError (get_file_path_from_url (newRequest.url ()), operation, newRequest);
        }
        if (!reply) {
            const bool isUpload = newRequest.url ().path ().startsWith (sUploadUrl.path ());
            FileInfo info = isUpload ? this.upload_file_info : this.remote_root_file_info;

            var verb = newRequest.attribute (Soup.Request.CustomVerbAttribute);
            if (verb == QLatin1String ("PROPFIND")) {
                // Ignore outgoing_data always returning somethign good enough, works for now.
                reply = new FakePropfindReply ( info, operation, newRequest, this };
            } else if (verb == QLatin1String ("GET") || operation == Soup.GetOperation) {
                reply = new FakeGetReply ( info, operation, newRequest, this };
            } else if (verb == QLatin1String ("PUT") || operation == Soup.PutOperation) {
                reply = new FakePutReply ( info, operation, newRequest, outgoing_data.readAll (), this };
            } else if (verb == QLatin1String ("MKCOL")) {
                reply = new FakeMkcolReply ( info, operation, newRequest, this };
            } else if (verb == QLatin1String ("DELETE") || operation == Soup.DeleteOperation) {
                reply = new FakeDeleteReply ( info, operation, newRequest, this };
            } else if (verb == QLatin1String ("MOVE") && !isUpload) {
                reply = new FakeMoveReply ( info, operation, newRequest, this };
            } else if (verb == QLatin1String ("MOVE") && isUpload) {
                reply = new FakeChunkMoveReply ( info, this.remote_root_file_info, operation, newRequest, this };
            } else if (verb == QLatin1String ("POST") || operation == Soup.PostOperation) {
                if (content_type.startsWith (QStringLiteral ("multipart/related; boundary="))) {
                    reply = new FakePutMultiFileReply ( info, operation, newRequest, content_type, outgoing_data.readAll (), this };
                }
            } else {
                GLib.debug () + verb + outgoing_data;
                Q_UNREACHABLE ();
            }
        }
        Occ.HttpLogger.logRequest (reply, operation, outgoing_data);
        return reply;
    }

}
}








