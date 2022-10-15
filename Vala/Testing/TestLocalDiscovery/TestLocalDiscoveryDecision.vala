namespace Occ {
namespace Testing {

/***********************************************************
@class TestLocalDiscoveryDecision

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestLocalDiscoveryDecision { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestLocalDiscoveryDecision () {
        //  FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        //  var engine = fake_folder.sync_engine;

        //  GLib.assert_true (engine.should_discover_locally (""));
        //  GLib.assert_true (engine.should_discover_locally ("A"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X"));

        //  fake_folder.sync_engine.set_local_discovery_options (
        //      LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A/X", "A/X space", "A/X/beta", "foo bar space/touch", "foo/", "zzz", "zzzz" });

        //  GLib.assert_true (engine.should_discover_locally (""));
        //  GLib.assert_true (engine.should_discover_locally ("A"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X"));
        //  GLib.assert_true (!engine.should_discover_locally ("B"));
        //  GLib.assert_true (!engine.should_discover_locally ("A B"));
        //  GLib.assert_true (!engine.should_discover_locally ("B/X"));
        //  GLib.assert_true (engine.should_discover_locally ("foo bar space"));
        //  GLib.assert_true (engine.should_discover_locally ("foo"));
        //  GLib.assert_true (!engine.should_discover_locally ("foo bar"));
        //  GLib.assert_true (!engine.should_discover_locally ("foo bar/touch"));
        //  // These are within "A/X" so they should be discovered
        //  GLib.assert_true (engine.should_discover_locally ("A/X/alpha"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X beta"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X/Y"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X space"));
        //  GLib.assert_true (engine.should_discover_locally ("A/X space/alpha"));
        //  GLib.assert_true (!engine.should_discover_locally ("A/Xylo/foo"));
        //  GLib.assert_true (engine.should_discover_locally ("zzzz/hello"));
        //  GLib.assert_true (!engine.should_discover_locally ("zzza/hello"));

        //  GLib.assert_fail ("", "There is a possibility of false positives if the set contains a path " +
        //      "which is a prefix, and that prefix is followed by a character less than "/"", Continue);
        //  GLib.assert_true (!engine.should_discover_locally ("A/X o"));

        //  fake_folder.sync_engine.set_local_discovery_options (
        //      LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, {});

        //  GLib.assert_true (!engine.should_discover_locally (""));
    }

} // class TestLocalDiscoveryDecision

} // namespace Testing
} // namespace Occ
