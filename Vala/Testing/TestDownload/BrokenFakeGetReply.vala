/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

/***********************************************************
A FakeGetReply that sends max 'fakeSize' bytes, but whose
ContentLength has the corect size
***********************************************************/
class BrokenFakeGetReply : FakeGetReply {

    using FakeGetReply.FakeGetReply;
    public int fakeSize = STOP_AFTER;

    /***********************************************************
    ***********************************************************/
    public int64 bytesAvailable () override {
        if (aborted)
            return 0;
        return std.min (size, fakeSize) + QIODevice.bytesAvailable (); // NOLINT : This is intended to simulare the brokeness
    }


    /***********************************************************
    ***********************************************************/
    public int64 readData (char data, int64 maxlen) override {
        int64 len = std.min (int64{ fakeSize }, maxlen);
        std.fill_n (data, len, payload);
        size -= len;
        fakeSize -= len;
        return len;
    }
}

SyncFileItemPtr getItem (QSignalSpy spy, string path) {
    for (GLib.List<GLib.Variant> args : spy) {
        var item = args[0].value<SyncFileItemPtr> ();
        if (item.destination () == path)
            return item;
    }
    return {};
}