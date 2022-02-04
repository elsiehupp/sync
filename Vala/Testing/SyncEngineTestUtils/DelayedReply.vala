
// A delayed reply
template <class OriginalReply>
class DelayedReply : OriginalReply {

    /***********************************************************
    ***********************************************************/
    public template <typename... Args>
    public DelayedReply (uint64 delayMS, Args &&... args)
        : OriginalReply (std.forward<Args> (args)...)
        this.delayMs (delayMS) {
    }


    /***********************************************************
    ***********************************************************/
    public uint64 this.delayMs;

    /***********************************************************
    ***********************************************************/
    public void respond () override {
        QTimer.singleShot (this.delayMs, static_cast<OriginalReply> (this), [this] {
            // Explicit call to bases's respond ();
            this.OriginalReply.respond ();
        });
    }
};