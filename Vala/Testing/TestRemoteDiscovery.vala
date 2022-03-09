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
                               const Soup.Request request, GLib.Object parent)
        : FakePropfindReply (remote_root_file_info, operation, request, parent) {
        // If the propfind contains a single file without permissions, this is a server error
        const string toRemove = "<oc:permissions>RDNVCKW</oc:permissions>";
        var position = payload.index_of (toRemove, payload.size ()/2);
        GLib.assert_true (position > 0);
        payload.remove (position, sizeof (toRemove) - 1);
    }
}

enum ErrorKind : int {
    // Lower code are corresponding to HTML error code
    InvalidXML = 1000,
    Timeout,
}

// Q_DECLARE_METATYPE (ErrorCategory)

class TestRemoteDiscovery : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testRemoteDiscoveryError_data () {
        qRegisterMetaType<ErrorCategory> ();
        QTest.add_column<int> ("errorKind");
        QTest.add_column<string> ("expectedErrorString");
        QTest.add_column<bool> ("syncSucceeds");

        string itemErrorMessage = "Internal Server Fake Error";

        QTest.new_row ("400") << 400 << itemErrorMessage + false;
        QTest.new_row ("401") << 401 << itemErrorMessage + false;
        QTest.new_row ("403") << 403 << itemErrorMessage + true;
        QTest.new_row ("404") << 404 << itemErrorMessage + true;
        QTest.new_row ("500") << 500 << itemErrorMessage + true;
        QTest.new_row ("503") << 503 << itemErrorMessage + true;
        // 200 should be an error since propfind should return 207
        QTest.new_row ("200") << 200 << itemErrorMessage + false;
        QTest.new_row ("InvalidXML") + +InvalidXML + "Unknown error" + false;
        QTest.new_row ("Timeout") + +Timeout + "Operation canceled" + false;
    }

    // Check what happens when there is an error.
    private void testRemoteDiscoveryError () {
        QFETCH (int, errorKind);
        QFETCH (string, expectedErrorString);
        QFETCH (bool, syncSucceeds);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        // Do Some change as well
        fake_folder.local_modifier ().insert ("A/z1");
        fake_folder.local_modifier ().insert ("B/z1");
        fake_folder.local_modifier ().insert ("C/z1");
        fake_folder.remote_modifier ().insert ("A/z2");
        fake_folder.remote_modifier ().insert ("B/z2");
        fake_folder.remote_modifier ().insert ("C/z2");

        var oldLocalState = fake_folder.current_local_state ();
        var oldRemoteState = fake_folder.current_remote_state ();

        string errorFolder = "dav/files/admin/B";
        string fatalErrorPrefix = "Server replied with an error while reading directory \"B\": ";
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *)
                . Soup.Reply *{
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url ().path ().ends_with (errorFolder)) {
                if (errorKind == InvalidXML) {
                    return new FakeBrokenXmlPropfindReply (fake_folder.remote_modifier (), operation, request, this);
                } else if (errorKind == Timeout) {
                    return new FakeHangingReply (operation, request, this);
                } else if (errorKind < 1000) {
                    return new FakeErrorReply (operation, request, this, errorKind);
                }
            }
            return null;
        });

        // So the test that test timeout finishes fast
        QScopedValueRollback<int> set_http_timeout (AbstractNetworkJob.http_timeout, errorKind == Timeout ? 1 : 10000);

        ItemCompletedSpy complete_spy (fake_folder);
        QSignalSpy errorSpy (&fake_folder.sync_engine (), &SyncEngine.syncError);
        GLib.assert_cmp (fake_folder.sync_once (), syncSucceeds);

        // The folder B should not have been sync'ed (and in particular not removed)
        GLib.assert_cmp (oldLocalState.children["B"], fake_folder.current_local_state ().children["B"]);
        GLib.assert_cmp (oldRemoteState.children["B"], fake_folder.current_remote_state ().children["B"]);
        if (!syncSucceeds) {
            GLib.assert_cmp (errorSpy.size (), 1);
            GLib.assert_cmp (errorSpy[0][0].to_string (), string (fatalErrorPrefix + expectedErrorString));
        } else {
            GLib.assert_cmp (complete_spy.find_item ("B").instruction, CSYNC_INSTRUCTION_IGNORE);
            GLib.assert_true (complete_spy.find_item ("B").error_string.contains (expectedErrorString));

            // The other folder should have been sync'ed as the sync just ignored the faulty directory
            GLib.assert_cmp (fake_folder.current_remote_state ().children["A"], fake_folder.current_local_state ().children["A"]);
            GLib.assert_cmp (fake_folder.current_remote_state ().children["C"], fake_folder.current_local_state ().children["C"]);
            GLib.assert_cmp (complete_spy.find_item ("A/z1").instruction, CSYNC_INSTRUCTION_NEW);
        }

        //
        // Check the same discovery error on the sync root
        //
        errorFolder = "dav/files/admin/";
        fatalErrorPrefix = "Server replied with an error while reading directory \"\": ";
        errorSpy.clear ();
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_cmp (errorSpy.size (), 1);
        GLib.assert_cmp (errorSpy[0][0].to_string (), string (fatalErrorPrefix + expectedErrorString));
    }


    /***********************************************************
    ***********************************************************/
    private void testMissingData () {
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

        ItemCompletedSpy complete_spy (fake_folder);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_cmp (complete_spy.find_item ("good").instruction, CSYNC_INSTRUCTION_NEW);
        GLib.assert_cmp (complete_spy.find_item ("noetag").instruction, CSYNC_INSTRUCTION_ERROR);
        GLib.assert_cmp (complete_spy.find_item ("nofileid").instruction, CSYNC_INSTRUCTION_ERROR);
        GLib.assert_cmp (complete_spy.find_item ("nopermissions").instruction, CSYNC_INSTRUCTION_NEW);
        GLib.assert_cmp (complete_spy.find_item ("nopermissions/A").instruction, CSYNC_INSTRUCTION_ERROR);
        GLib.assert_true (complete_spy.find_item ("noetag").error_string.contains ("ETag"));
        GLib.assert_true (complete_spy.find_item ("nofileid").error_string.contains ("file identifier"));
        GLib.assert_true (complete_spy.find_item ("nopermissions/A").error_string.contains ("permission"));
    }
}

QTEST_GUILESS_MAIN (TestRemoteDiscovery)
