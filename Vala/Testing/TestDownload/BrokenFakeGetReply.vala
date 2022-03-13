/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

/***********************************************************
A FakeGetReply that sends max 'fake_size' bytes, but whose
ContentLength has the corect size
***********************************************************/
public class BrokenFakeGetReply : FakeGetReply {

    //  using FakeGetReply.FakeGetReply;
    public int fake_size = STOP_AFTER;

    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        if (aborted) {
            return 0;
        }
        return std.min (size, fake_size) + QIODevice.bytes_available (); // NOLINT : This is intended to simulare the brokeness
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        int64 len = std.min ((int64) fake_size, maxlen);
        std.fill_n (data, len, payload);
        size -= len;
        fake_size -= len;
        return len;
    }


    /***********************************************************
    ***********************************************************/
    SyncFileItemPtr get_item (QSignalSpy spy, string path) {
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
