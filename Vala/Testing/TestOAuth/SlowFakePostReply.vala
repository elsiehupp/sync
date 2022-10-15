/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

// Reply with a small delay
public class SlowFakePostReply : FakePostReply {

    /***********************************************************
    ***********************************************************/
    public override void respond () {
        //  // override of FakePostReply.respond, will call the real one with a delay.
        //  GLib.Timeout.add (
        //      100,
        //      base.respond ()
        //  );
    }
}
