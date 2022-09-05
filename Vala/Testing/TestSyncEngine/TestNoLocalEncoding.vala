/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestNoLocalEncoding : AbstractTestSyncEngine {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestNoLocalEncoding () {
    //      var utf8Locale = GMime.Encoding.codec_for_locale ();
    //      if (utf8Locale.mib_enum () != 106) {
    //          GLib.SKIP ("Test only works for UTF8 locale");
    //      }

    //      FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

    //      // Utf8 locale can sync both
    //      fake_folder.remote_modifier ().insert ("A/tößt");
    //      fake_folder.remote_modifier ().insert ("A/t𠜎t");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state ().find ("A/tößt"));
    //      GLib.assert_true (fake_folder.current_local_state ().find ("A/t𠜎t"));

    //      // Try again with a locale that can represent ö but not 𠜎 (4-byte utf8).
    //      GMime.Encoding.set_codec_for_locale (GMime.Encoding.codec_for_name ("ISO-8859-15"));
    //      GLib.assert_true (GMime.Encoding.codec_for_locale ().mib_enum () == 111);

    //      fake_folder.remote_modifier ().insert ("B/tößt");
    //      fake_folder.remote_modifier ().insert ("B/t𠜎t");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_local_state ().find ("B/tößt"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/t𠜎t"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/t?t"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/t??t"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/t???t"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("B/t????t"));
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("B/tößt"));
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("B/t𠜎t"));

    //      // Try again with plain ascii
    //      GMime.Encoding.set_codec_for_locale (GMime.Encoding.codec_for_name ("ASCII"));
    //      GLib.assert_true (GMime.Encoding.codec_for_locale ().mib_enum () == 3);

    //      fake_folder.remote_modifier ().insert ("C/tößt");
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("C/tößt"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("C/t??t"));
    //      GLib.assert_true (!fake_folder.current_local_state ().find ("C/t????t"));
    //      GLib.assert_true (fake_folder.sync_once ());
    //      GLib.assert_true (fake_folder.current_remote_state ().find ("C/tößt"));

    //      GMime.Encoding.set_codec_for_locale (utf8Locale);
    //  }

} // class TestNoLocalEncoding

} // namespace Testing
} // namespace Occ
