/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

// Reply with a small delay
class SlowFakePostReply : FakePostReply {

    /***********************************************************
    ***********************************************************/
    public override void respond () {
        // override of FakePostReply.respond, will call the real one with a delay.
        QTimer.single_shot (
            100,
            this,
            [this] () => {
                this.FakePostReply.respond ();
            });
    }
}
