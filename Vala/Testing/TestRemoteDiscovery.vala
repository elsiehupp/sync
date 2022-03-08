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
        //  QVERIFY (payload.size () > 50);
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
        var position = payload.indexOf (toRemove, payload.size ()/2);
        //  QVERIFY (position > 0);
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
        QTest.addColumn<int> ("errorKind");
        QTest.addColumn<string> ("expectedErrorString");
        QTest.addColumn<bool> ("syncSucceeds");

        string itemErrorMessage = "Internal Server Fake Error";

        QTest.newRow ("400") << 400 << itemErrorMessage + false;
        QTest.newRow ("401") << 401 << itemErrorMessage + false;
        QTest.newRow ("403") << 403 << itemErrorMessage + true;
        QTest.newRow ("404") << 404 << itemErrorMessage + true;
        QTest.newRow ("500") << 500 << itemErrorMessage + true;
        QTest.newRow ("503") << 503 << itemErrorMessage + true;
        // 200 should be an error since propfind should return 207
        QTest.newRow ("200") << 200 << itemErrorMessage + false;
        QTest.newRow ("InvalidXML") + +InvalidXML + "Unknown error" + false;
        QTest.newRow ("Timeout") + +Timeout + "Operation canceled" + false;
    }

    // Check what happens when there is an error.
    private void testRemoteDiscoveryError () {
        //  QFETCH (int, errorKind);
        //  QFETCH (string, expectedErrorString);
        //  QFETCH (bool, syncSucceeds);

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
        string fatalErrorPrefix = "Server replied with an error while reading directory \"B\" : ";
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *)
                . Soup.Reply *{
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url ().path ().endsWith (errorFolder)) {
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
        QScopedValueRollback<int> setHttpTimeout (AbstractNetworkJob.httpTimeout, errorKind == Timeout ? 1 : 10000);

        ItemCompletedSpy completeSpy (fake_folder);
        QSignalSpy errorSpy (&fake_folder.sync_engine (), &SyncEngine.syncError);
        //  QCOMPARE (fake_folder.sync_once (), syncSucceeds);

        // The folder B should not have been sync'ed (and in particular not removed)
        //  QCOMPARE (oldLocalState.children["B"], fake_folder.current_local_state ().children["B"]);
        //  QCOMPARE (oldRemoteState.children["B"], fake_folder.current_remote_state ().children["B"]);
        if (!syncSucceeds) {
            //  QCOMPARE (errorSpy.size (), 1);
            //  QCOMPARE (errorSpy[0][0].to_string (), string (fatalErrorPrefix + expectedErrorString));
        } else {
            //  QCOMPARE (completeSpy.findItem ("B").instruction, CSYNC_INSTRUCTION_IGNORE);
            //  QVERIFY (completeSpy.findItem ("B").errorString.contains (expectedErrorString));

            // The other folder should have been sync'ed as the sync just ignored the faulty directory
            //  QCOMPARE (fake_folder.current_remote_state ().children["A"], fake_folder.current_local_state ().children["A"]);
            //  QCOMPARE (fake_folder.current_remote_state ().children["C"], fake_folder.current_local_state ().children["C"]);
            //  QCOMPARE (completeSpy.findItem ("A/z1").instruction, CSYNC_INSTRUCTION_NEW);
        }

        //
        // Check the same discovery error on the sync root
        //
        errorFolder = "dav/files/admin/";
        fatalErrorPrefix = "Server replied with an error while reading directory \"\" : ";
        errorSpy.clear ();
        //  QVERIFY (!fake_folder.sync_once ());
        //  QCOMPARE (errorSpy.size (), 1);
        //  QCOMPARE (errorSpy[0][0].to_string (), string (fatalErrorPrefix + expectedErrorString));
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
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND" && request.url ().path ().endsWith ("nopermissions"))
                return new MissingPermissionsPropfindReply (fake_folder.remote_modifier (), operation, request, this);
            return null;
        });

        ItemCompletedSpy completeSpy (fake_folder);
        //  QVERIFY (!fake_folder.sync_once ());

        //  QCOMPARE (completeSpy.findItem ("good").instruction, CSYNC_INSTRUCTION_NEW);
        //  QCOMPARE (completeSpy.findItem ("noetag").instruction, CSYNC_INSTRUCTION_ERROR);
        //  QCOMPARE (completeSpy.findItem ("nofileid").instruction, CSYNC_INSTRUCTION_ERROR);
        //  QCOMPARE (completeSpy.findItem ("nopermissions").instruction, CSYNC_INSTRUCTION_NEW);
        //  QCOMPARE (completeSpy.findItem ("nopermissions/A").instruction, CSYNC_INSTRUCTION_ERROR);
        //  QVERIFY (completeSpy.findItem ("noetag").errorString.contains ("ETag"));
        //  QVERIFY (completeSpy.findItem ("nofileid").errorString.contains ("file identifier"));
        //  QVERIFY (completeSpy.findItem ("nopermissions/A").errorString.contains ("permission"));
    }
}

QTEST_GUILESS_MAIN (TestRemoteDiscovery)
