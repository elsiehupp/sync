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
    public FakePropfindReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent);

    /***********************************************************
    ***********************************************************/
    public void respond ();

    /***********************************************************
    ***********************************************************/
    public void respond_404 ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () override { }


    /***********************************************************
    ***********************************************************/
    public int64 bytes_available () override;

    /***********************************************************
    ***********************************************************/
    public int64 read_data (char data, int64 maxlen) override;

}
}





FakePropfindReply.FakePropfindReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent)
    : FakeReply (parent); {
    set_request (request);
    set_url (request.url ());
    set_operation (operation);
    open (QIODevice.ReadOnly);

    string fileName = get_file_path_from_url (request.url ());
    //  Q_ASSERT (!fileName.isNull ()); // for root, it should be empty
    const FileInfo file_info = remote_root_file_info.find (fileName);
    if (!file_info) {
        QMetaObject.invoke_method (this, "respond_404", Qt.QueuedConnection);
        return;
    }
    const string prefix = request.url ().path ().left (request.url ().path ().size () - fileName.size ());

    // Don't care about the request and just return a full propfind
    const string davUri ( QStringLiteral ("DAV:"));
    const string ocUri ( QStringLiteral ("http://owncloud.org/ns"));
    QBuffer buffer ( payload };
    buffer.open (QIODevice.WriteOnly);
    QXmlStreamWriter xml (&buffer);
    xml.writeNamespace (davUri, QStringLiteral ("d"));
    xml.writeNamespace (ocUri, QStringLiteral ("oc"));
    xml.writeStartDocument ();
    xml.writeStartElement (davUri, QStringLiteral ("multistatus"));
    var writeFileResponse = [&] (FileInfo file_info) {
        xml.writeStartElement (davUri, QStringLiteral ("response"));

        var url = string.fromUtf8 (GLib.Uri.toPercentEncoding (file_info.absolutePath (), "/"));
        if (!url.endsWith (char ('/'))) {
            url.append (char ('/'));
        }
        const var href = Occ.Utility.concatUrlPath (prefix, url).path ();
        xml.writeTextElement (davUri, QStringLiteral ("href"), href);
        xml.writeStartElement (davUri, QStringLiteral ("propstat"));
        xml.writeStartElement (davUri, QStringLiteral ("prop"));

        if (file_info.isDir) {
            xml.writeStartElement (davUri, QStringLiteral ("resourcetype"));
            xml.writeEmptyElement (davUri, QStringLiteral ("collection"));
            xml.writeEndElement (); // resourcetype
        } else
            xml.writeEmptyElement (davUri, QStringLiteral ("resourcetype"));

        var gmtDate = file_info.lastModified.toUTC ();
        var stringDate = QLocale.c ().toString (gmtDate, QStringLiteral ("ddd, dd MMM yyyy HH:mm:ss 'GMT'"));
        xml.writeTextElement (davUri, QStringLiteral ("getlastmodified"), stringDate);
        xml.writeTextElement (davUri, QStringLiteral ("getcontentlength"), string.number (file_info.size));
        xml.writeTextElement (davUri, QStringLiteral ("getetag"), QStringLiteral ("\"%1\"").arg (string.fromLatin1 (file_info.etag)));
        xml.writeTextElement (ocUri, QStringLiteral ("permissions"), !file_info.permissions.isNull () ? string (file_info.permissions.toString ()) : file_info.isShared ? QStringLiteral ("SRDNVCKW") : QStringLiteral ("RDNVCKW"));
        xml.writeTextElement (ocUri, QStringLiteral ("identifier"), string.fromUtf8 (file_info.file_identifier));
        xml.writeTextElement (ocUri, QStringLiteral ("checksums"), string.fromUtf8 (file_info.checksums));
        buffer.write (file_info.extraDavProperties);
        xml.writeEndElement (); // prop
        xml.writeTextElement (davUri, QStringLiteral ("status"), QStringLiteral ("HTTP/1.1 200 OK"));
        xml.writeEndElement (); // propstat
        xml.writeEndElement (); // response
    }

    writeFileResponse (*file_info);
    foreach (FileInfo childFileInfo, file_info.children)
        writeFileResponse (childFileInfo);
    xml.writeEndElement (); // multistatus
    xml.writeEndDocument ();

    QMetaObject.invoke_method (this, "respond", Qt.QueuedConnection);
}

void FakePropfindReply.respond () {
    setHeader (Soup.Request.ContentLengthHeader, payload.size ());
    setHeader (Soup.Request.ContentTypeHeader, QByteArrayLiteral ("application/xml; charset=utf-8"));
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 207);
    setFinished (true);
    /* emit */ signal_meta_data_changed ();
    if (bytes_available ())
        /* emit */ readyRead ();
    /* emit */ signal_finished ();
}

void FakePropfindReply.respond_404 () {
    set_attribute (Soup.Request.HttpStatusCodeAttribute, 404);
    set_error (InternalServerError, QStringLiteral ("Not Found"));
    /* emit */ signal_meta_data_changed ();
    /* emit */ signal_finished ();
}

int64 FakePropfindReply.bytes_available () {
    return payload.size () + QIODevice.bytes_available ();
}

int64 FakePropfindReply.read_data (char data, int64 maxlen) {
    int64 len = std.min (int64 { payload.size () }, maxlen);
    std.copy (payload.cbegin (), payload.cbegin () + len, data);
    payload.remove (0, static_cast<int> (len));
    return len;
}