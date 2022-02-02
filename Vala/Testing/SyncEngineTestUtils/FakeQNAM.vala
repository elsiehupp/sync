/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeQNAM : QNetworkAccessManager {

    /***********************************************************
    ***********************************************************/
    public using Override = std.function<Soup.Reply * (Operation, QNetworkRequest &, QIODevice *)>;


    /***********************************************************
    ***********************************************************/
    private FileInfo this.remoteRootFileInfo;
    private FileInfo this.uploadFileInfo;
    // maps a path to an HTTP error
    private GLib.HashMap<string, int> this.errorPaths;
    // monitor requests and optionally provide custom replies
    private Override this.override;


    /***********************************************************
    ***********************************************************/
    public FakeQNAM (FileInfo initialRoot);

    /***********************************************************
    ***********************************************************/
    public 
    public FileInfo currentRemoteState () { return this.remoteRootFileInfo; }
    public FileInfo uploadState () { return this.uploadFileInfo; }


    /***********************************************************
    ***********************************************************/
    public GLib.HashMap<string, int> errorPaths () { return this.errorPaths; }

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public QJsonObject forEachReplyPart (QIODevice outgoingData,
                                 const string contentType,
                                 std.function<QJsonObject (GLib.HashMap<string, GLib.ByteArray> &)> replyFunction);

    /***********************************************************
    ***********************************************************/
    public Soup.Reply overrideReplyWithError (string fileName, Operation op, QNetworkRequest newRequest);


    protected Soup.Reply createRequest (Operation op, QNetworkRequest request,
        QIODevice outgoingData = nullptr) override;
};