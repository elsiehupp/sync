

namespace Testing {

//  template <class OriginalReply>

/***********************************************************
A delayed reply
***********************************************************/
class DelayedReply : OriginalReply {

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
        QTimer.singleShot (this.delay_milliseconds, static_cast<OriginalReply> (this), () => {
            // Explicit call to bases's respond ();
            this.OriginalReply.respond ();
        });
    }

} // class DelayedReply
} // namespace Testing
