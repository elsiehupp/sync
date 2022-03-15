/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

public class FakeReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public FakeReply (GLib.Object parent) {
        base (parent);
        set_raw_header (new string ("Date"), GLib.DateTime.current_date_time_utc ().to_string (Qt.RFC2822Date));
    }


    /***********************************************************
    Useful to be public for testing
    ***********************************************************/
    //  using Soup.Reply.set_raw_header;

} // class FakeReply
} // namespace Testing
