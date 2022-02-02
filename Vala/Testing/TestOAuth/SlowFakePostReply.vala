/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using namespace Occ;

// Reply with a small delay
class SlowFakePostReply : FakePostReply {

    /***********************************************************
    ***********************************************************/
    public using FakePostReply.FakePostReply;
    public void respond () override {
        // override of FakePostReply.respond, will call the real one with a delay.
        QTimer.singleShot (100, this, [this] { this.FakePostReply.respond (); });
    }
}
