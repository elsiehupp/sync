/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

/***********************************************************
A FakeGetReply that sends max 'fakeSize' bytes, but whose
ContentLength has the corect size
***********************************************************/
class BrokenFakeGetReply : FakeGetReply {

    //  using FakeGetReply.FakeGetReply;
    public int fakeSize = STOP_AFTER;

    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        if (aborted) {
            return 0;
        }
        return std.min (size, fakeSize) + QIODevice.bytes_available (); // NOLINT : This is intended to simulare the brokeness
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char data, int64 maxlen) {
        int64 len = std.min ((int64) fakeSize, maxlen);
        std.fill_n (data, len, payload);
        size -= len;
        fakeSize -= len;
        return len;
    }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr getItem (QSignalSpy spy, string path) {
        foreach (GLib.List<GLib.Variant> args in spy) {
            var item = args[0].value<SyncFileItemPtr> ();
            if (item.destination () == path) {
                return item;
            }
        }
        return {};
    }

} // class BrokenFakeGetReply
} // namespace Testing
