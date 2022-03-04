/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public FakeReply (GLib.Object parent);


    ~FakeReply () override;

    /***********************************************************
    Useful to be public for testing
    ***********************************************************/
    using Soup.Reply.setRawHeader;

}
}








FakeReply.FakeReply (GLib.Object parent)
    : Soup.Reply (parent) {
    setRawHeader (QByteArrayLiteral ("Date"), GLib.DateTime.currentDateTimeUtc ().toString (Qt.RFC2822Date).toUtf8 ());
}

FakeReply.~FakeReply () = default;
