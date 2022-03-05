/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeJsonErrorReply : FakeErrorReply {

    /***********************************************************
    ***********************************************************/
    public FakeJsonErrorReply (
        Soup.Operation operation,
        Soup.Request request,
        GLib.Object parent,
        int http_error_code,
        QJsonDocument reply = QJsonDocument ()) {
        base (operation, request, parent, http_error_code, reply.toJson ());
    }

}
}
