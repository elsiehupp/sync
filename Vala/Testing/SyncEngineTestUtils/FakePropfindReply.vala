/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakePropfindReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray payload;

    /***********************************************************
    ***********************************************************/
    public FakePropfindReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url ());
        set_operation (operation);
        open (QIODevice.ReadOnly);

        string filename = get_file_path_from_url (request.url ());
        //  Q_ASSERT (!filename.isNull ()); // for root, it should be empty
        const FileInfo file_info = remote_root_file_info.find (filename);
        if (!file_info) {
            QMetaObject.invoke_method (this, "respond_404", Qt.QueuedConnection);
            return;
        }
        const string prefix = request.url ().path ().left (request.url ().path ().size () - filename.size ());

        // Don't care about the request and just return a full propfind
        const string davUri = "DAV:";
        const string ocUri = "http://owncloud.org/ns";
        QBuffer buffer = new QBuffer (payload);
        buffer.open (QIODevice.WriteOnly);
        QXmlStreamWriter xml = new QXmlStreamWriter (buffer);
        xml.writeNamespace (davUri, "d");
        xml.writeNamespace (ocUri, "oc");
        xml.writeStartDocument ();
        xml.writeStartElement (davUri, "multistatus");
        var writeFileResponse = (FileInfo file_info) => {
            xml.writeStartElement (davUri, "response");

            var url = string.fromUtf8 (GLib.Uri.toPercentEncoding (file_info.absolutePath (), "/"));
            if (!url.endsWith (char ('/'))) {
                url.append (char ('/'));
            }
            const string href = Occ.Utility.concatUrlPath (prefix, url).path ();
            xml.writeTextElement (davUri, "href", href);
            xml.writeStartElement (davUri, "propstat");
            xml.writeStartElement (davUri, "prop");

            if (file_info.isDir) {
                xml.writeStartElement (davUri, "resourcetype");
                xml.writeEmptyElement (davUri, "collection");
                xml.writeEndElement (); // resourcetype
            } else {
                xml.writeEmptyElement (davUri, "resourcetype");
            }

            var gmtDate = file_info.last_modified.toUTC ();
            var stringDate = QLocale.c ().to_string (gmtDate, "ddd, dd MMM yyyy HH:mm:ss 'GMT'");
            xml.writeTextElement (davUri, "getlastmodified", stringDate);
            xml.writeTextElement (davUri, "getcontentlength", string.number (file_info.size));
            xml.writeTextElement (davUri, "getetag", "\"%1\"".arg (string.fromLatin1 (file_info.etag)));
            xml.writeTextElement (ocUri, "permissions", !file_info.permissions.isNull () ? string (file_info.permissions.to_string ()) : file_info.isShared ? QStringLiteral ("SRDNVCKW") : QStringLiteral ("RDNVCKW"));
            xml.writeTextElement (ocUri, "identifier", string.fromUtf8 (file_info.file_identifier));
            xml.writeTextElement (ocUri, "checksums", string.fromUtf8 (file_info.checksums));
            buffer.write (file_info.extraDavProperties);
            xml.writeEndElement (); // prop
            xml.writeTextElement (davUri, "status", "HTTP/1.1 200 OK");
            xml.writeEndElement (); // propstat
            xml.writeEndElement (); // response
        }

        writeFileResponse (file_info);
        foreach (FileInfo childFileInfo in file_info.children) {
            writeFileResponse (childFileInfo);
        }
        xml.writeEndElement (); // multistatus
        xml.writeEndDocument ();

        QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
    }

    /***********************************************************
    ***********************************************************/
    public void respond () {
        setHeader (Soup.Request.ContentLengthHeader, payload.size ());
        setHeader (Soup.Request.ContentTypeHeader, QByteArrayLiteral ("application/xml; charset=utf-8"));
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 207);
        setFinished (true);
        /* emit */ signal_meta_data_changed ();
        if (bytes_available ()) {
            /* emit */ signal_ready_read ();
        }
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public void respond_404 () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 404);
        set_error (InternalServerError, "Not Found");
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
    public override int64 bytes_available () {
        return payload.size () + QIODevice.bytes_available ();
    }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        int64 len = std.min ((int64) payload.size (), maxlen);
        std.copy (payload.cbegin (), payload.cbegin () + len, data);
        payload.remove (0, static_cast<int> (len));
        return len;
    }

} // class FakePropfindReply
} // namespace Testing
