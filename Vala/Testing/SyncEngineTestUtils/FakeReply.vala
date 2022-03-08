/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public FakeReply (GLib.Object parent) {
        base (parent);
        set_raw_header (QByteArrayLiteral ("Date"), GLib.DateTime.currentDateTimeUtc ().to_string (Qt.RFC2822Date).toUtf8 ());
    }


    /***********************************************************
    Useful to be public for testing
    ***********************************************************/
    //  using Soup.Reply.set_raw_header;

} // class FakeReply
} // namespace Testing
