

namespace Occ {
namespace Testing {

//  template <class OriginalReply>

/***********************************************************
A delayed reply
***********************************************************/
public class DelayedReply<OriginalReply> : FakeReply {

    /***********************************************************
    ***********************************************************/
    public uint delay_milliseconds;

    /***********************************************************
    ***********************************************************/
    public DelayedReply (uint64 delay_milliseconds, GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
        //  this.delay_milliseconds = delay_milliseconds;
    }

    /***********************************************************
    ***********************************************************/
    public void respond () {
        //  GLib.Timeout.add (this.delay_milliseconds, this.on_signal_timeout);
    }


    /***********************************************************
    Explicit call to bases's respond ();
    ***********************************************************/
    private bool on_signal_timeout () {
        //  ((OriginalReply)base).respond ();
    }

} // class DelayedReply
} // namespace Testing
} // namespace Occ
