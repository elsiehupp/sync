

namespace Occ {
namespace Testing {

//  template <class OriginalReply>

/***********************************************************
A delayed reply
***********************************************************/
public class DelayedReply<OriginalReply> : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public uint64 delay_milliseconds;

    /***********************************************************
    ***********************************************************/
    //  //  public template <typename... Args>
    //  public DelayedReply (uint64 delay_milliseconds, Args &&... args) {
    //      base (std.forward<Args> (args)...);
    //      this.delay_milliseconds = delay_milliseconds;
    //  }

    /***********************************************************
    ***********************************************************/
    public void respond () {
        GLib.Timeout.single_shot (this.delay_milliseconds, (OriginalReply)this, () => {
            // Explicit call to bases's respond ();
            this.OriginalReply.respond ();
        });
    }

} // class DelayedReply
} // namespace Testing
} // namespace Occ
