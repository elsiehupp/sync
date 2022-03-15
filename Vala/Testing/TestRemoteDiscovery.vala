/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <localdiscoverytracker.h>

using Occ;

namespace Testing {

struct FakeBrokenXmlPropfindReply : FakePropfindReply {
    FakeBrokenXmlPropfindReply (FileInfo remote_root_file_info, Soup.Operation operation,
                               const Soup.Request request, GLib.Object parent)
        : FakePropfindReply (remote_root_file_info, operation, request, parent) {
        GLib.assert_true (payload.size () > 50);
        // turncate the XML
        payload.chop (20);
    }
}

struct MissingPermissionsPropfindReply : FakePropfindReply {
    MissingPermissionsPropfindReply (FileInfo remote_root_file_info, Soup.Operation operation,
        Soup.Request request, GLib.Object parent) {
        base (remote_root_file_info, operation, request, parent);
        // If the propfind contains a single file without permissions, this is a server error
        const string to_remove = "<oc:permissions>RDNVCKW</oc:permissions>";
        var position = payload.index_of (to_remove, payload.size ()/2);
        GLib.assert_true (position > 0);
        payload.remove (position, sizeof (to_remove) - 1);
    }
}

enum ErrorKind : int {
    // Lower code are corresponding to HTML error code
    InvalidXML = 1000,
    Timeout,
}

// Q_DECLARE_METATYPE (ErrorCategory)

public class TestRemoteDiscovery : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void test_remote_discovery_error_data () {
        //  QRegisterMetaType<ErrorCategory> ();
        QTest.add_column<int> ("error_kind");
        QTest.add_column<string> ("expected_error_string");
        QTest.add_column<bool> ("sync_succeeds");

        string item_error_message = "Internal Server Fake Error";

        QTest.new_row ("400") << 400 << item_error_message + false;
        QTest.new_row ("401") << 401 << item_error_message + false;
        QTest.new_row ("403") << 403 << item_error_message + true;
        QTest.new_row ("404") << 404 << item_error_message + true;
        QTest.new_row ("500") << 500 << item_error_message + true;
        QTest.new_row ("503") << 503 << item_error_message + true;
        // 200 should be an error since propfind should return 207
        QTest.new_row ("200") << 200 << item_error_message + false;
        QTest.new_row ("InvalidXML") + +InvalidXML + "Unknown error" + false;
        QTest.new_row ("Timeout") + +Timeout + "Operation canceled" + false;
    }

    // Check what happens when there is an error.
    private void test_remote_discovery_error () {
        QFETCH (int, error_kind);
        QFETCH (string, expected_error_string);
        QFETCH (bool, sync_succeeds);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Do Some change as well
        fake_folder.local_modifier ().insert ("A/z1");
        fake_folder.local_modifier ().insert ("B/z1");
        fake_folder.local_modifier ().insert ("C/z1");
        fake_folder.remote_modifier ().insert ("A/z2");
        fake_folder.remote_modifier ().insert ("B/z2");
        fake_folder.remote_modifier ().insert ("C/z2");

        var old_local_state = fake_folder.current_local_state ();
        var old_remote_state = fake_folder.current_remote_state ();

        string error_folder = "dav/files/admin/B";
        string fatal_error_prefix = "Server replied with an error while reading directory \"B\": ";
        fake_folder.set_server_override (
            [&] (Soup.Operation operation, Soup.Request request, QIODevice *) => Soup.Reply *{
                if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url ().path ().ends_with (error_folder)) {
                    if (error_kind == InvalidXML) {
                        return new FakeBrokenXmlPropfindReply (fake_folder.remote_modifier (), operation, request, this);
                    } else if (error_kind == Timeout) {
                        return new FakeHangingReply (operation, request, this);
                    } else if (error_kind < 1000) {
                        return new FakeErrorReply (operation, request, this, error_kind);
                    }
                }
                return null;
            }
        );

        // So the test that test timeout finishes fast
        QScopedValueRollback<int> set_http_timeout (AbstractNetworkJob.http_timeout, error_kind == Timeout ? 1 : 10000);

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        QSignalSpy error_spy = new QSignalSpy (
            fake_folder.sync_engine (),
            SyncEngine.sync_error
        );
        GLib.assert_cmp (fake_folder.sync_once (), sync_succeeds);

        // The folder B should not have been sync'ed (and in particular not removed)
        GLib.assert_cmp (old_local_state.children["B"], fake_folder.current_local_state ().children["B"]);
        GLib.assert_cmp (old_remote_state.children["B"], fake_folder.current_remote_state ().children["B"]);
        if (!sync_succeeds) {
            GLib.assert_cmp (error_spy.size (), 1);
            GLib.assert_cmp (error_spy[0][0].to_string (), string (fatal_error_prefix + expected_error_string));
        } else {
            GLib.assert_cmp (complete_spy.find_item ("B").instruction, SyncInstructions.IGNORE);
            GLib.assert_true (complete_spy.find_item ("B").error_string.contains (expected_error_string));

            // The other folder should have been sync'ed as the sync just ignored the faulty directory
            GLib.assert_cmp (fake_folder.current_remote_state ().children["A"], fake_folder.current_local_state ().children["A"]);
            GLib.assert_cmp (fake_folder.current_remote_state ().children["C"], fake_folder.current_local_state ().children["C"]);
            GLib.assert_cmp (complete_spy.find_item ("A/z1").instruction, SyncInstructions.NEW);
        }

        //
        // Check the same discovery error on the sync root
        //
        error_folder = "dav/files/admin/";
        fatal_error_prefix = "Server replied with an error while reading directory \"\": ";
        error_spy.clear ();
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (error_spy.size (), 1);
        GLib.assert_cmp (error_spy[0][0].to_string (), string (fatal_error_prefix + expected_error_string));
    }


    /***********************************************************
    ***********************************************************/
    private void test_missing_data () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        fake_folder.remote_modifier ().insert ("good");
        fake_folder.remote_modifier ().insert ("noetag");
        fake_folder.remote_modifier ().find ("noetag").etag.clear ();
        fake_folder.remote_modifier ().insert ("nofileid");
        fake_folder.remote_modifier ().find ("nofileid").file_identifier.clear ();
        fake_folder.remote_modifier ().mkdir ("nopermissions");
        fake_folder.remote_modifier ().insert ("nopermissions/A");

        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *)
                . Soup.Reply *{
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url ().path ().ends_with ("nopermissions"))
                return new MissingPermissionsPropfindReply (fake_folder.remote_modifier (), operation, request, this);
            return null;
        });

        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_cmp (complete_spy.find_item ("good").instruction, SyncInstructions.NEW);
        GLib.assert_cmp (complete_spy.find_item ("noetag").instruction, SyncInstructions.ERROR);
        GLib.assert_cmp (complete_spy.find_item ("nofileid").instruction, SyncInstructions.ERROR);
        GLib.assert_cmp (complete_spy.find_item ("nopermissions").instruction, SyncInstructions.NEW);
        GLib.assert_cmp (complete_spy.find_item ("nopermissions/A").instruction, SyncInstructions.ERROR);
        GLib.assert_true (complete_spy.find_item ("noetag").error_string.contains ("ETag"));
        GLib.assert_true (complete_spy.find_item ("nofileid").error_string.contains ("file identifier"));
        GLib.assert_true (complete_spy.find_item ("nopermissions/A").error_string.contains ("permission"));
    }
}

QTEST_GUILESS_MAIN (TestRemoteDiscovery)
