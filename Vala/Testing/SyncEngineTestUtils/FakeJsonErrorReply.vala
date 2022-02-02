/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeJsonErrorReply : FakeErrorReply {

    /***********************************************************
    ***********************************************************/
    public FakeJsonErrorReply (QNetworkAccessManager.Operation op,
                       const QNetworkRequest request,
                       GLib.Object parent,
                       int httpErrorCode,
                       const QJsonDocument reply = QJsonDocument ());
};