/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

class FakeReply : Soup.Reply {

    /***********************************************************
    ***********************************************************/
    public FakeReply (GLib.Object parent);
    ~FakeReply () override;

    // useful to be public for testing
    using Soup.Reply.setRawHeader;
};