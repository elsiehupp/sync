/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <localdiscoverytracker.h>

using namespace Occ;

struct FakeBrokenXmlPropfindReply : FakePropfindReply {
    FakeBrokenXmlPropfindReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op,
                               const QNetworkRequest request, GLib.Object parent)
        : FakePropfindReply (remoteRootFileInfo, op, request, parent) {
        QVERIFY (payload.size () > 50);
        // turncate the XML
        payload.chop (20);
    }
}

struct MissingPermissionsPropfindReply : FakePropfindReply {
    MissingPermissionsPropfindReply (FileInfo remoteRootFileInfo, QNetworkAccessManager.Operation op,
                               const QNetworkRequest request, GLib.Object parent)
        : FakePropfindReply (remoteRootFileInfo, op, request, parent) {
        // If the propfind contains a single file without permissions, this is a server error
        const string toRemove = "<oc:permissions>RDNVCKW</oc:permissions>";
        var position = payload.indexOf (toRemove, payload.size ()/2);
        QVERIFY (position > 0);
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
    private on_ void testRemoteDiscoveryError_data () {
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
    private on_ void testRemoteDiscoveryError () {
        QFETCH (int, errorKind);
        QFETCH (string, expectedErrorString);
        QFETCH (bool, syncSucceeds);

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };

        // Do Some change as well
        fakeFolder.localModifier ().insert ("A/z1");
        fakeFolder.localModifier ().insert ("B/z1");
        fakeFolder.localModifier ().insert ("C/z1");
        fakeFolder.remoteModifier ().insert ("A/z2");
        fakeFolder.remoteModifier ().insert ("B/z2");
        fakeFolder.remoteModifier ().insert ("C/z2");

        var oldLocalState = fakeFolder.currentLocalState ();
        var oldRemoteState = fakeFolder.currentRemoteState ();

        string errorFolder = "dav/files/admin/B";
        string fatalErrorPrefix = "Server replied with an error while reading directory \"B\" : ";
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest req, QIODevice *)
                . Soup.Reply *{
            if (req.attribute (QNetworkRequest.CustomVerbAttribute) == "PROPFIND" && req.url ().path ().endsWith (errorFolder)) {
                if (errorKind == InvalidXML) {
                    return new FakeBrokenXmlPropfindReply (fakeFolder.remoteModifier (), op, req, this);
                } else if (errorKind == Timeout) {
                    return new FakeHangingReply (op, req, this);
                } else if (errorKind < 1000) {
                    return new FakeErrorReply (op, req, this, errorKind);
                }
            }
            return null;
        });

        // So the test that test timeout finishes fast
        QScopedValueRollback<int> setHttpTimeout (AbstractNetworkJob.httpTimeout, errorKind == Timeout ? 1 : 10000);

        ItemCompletedSpy completeSpy (fakeFolder);
        QSignalSpy errorSpy (&fakeFolder.syncEngine (), &SyncEngine.syncError);
        QCOMPARE (fakeFolder.syncOnce (), syncSucceeds);

        // The folder B should not have been sync'ed (and in particular not removed)
        QCOMPARE (oldLocalState.children["B"], fakeFolder.currentLocalState ().children["B"]);
        QCOMPARE (oldRemoteState.children["B"], fakeFolder.currentRemoteState ().children["B"]);
        if (!syncSucceeds) {
            QCOMPARE (errorSpy.size (), 1);
            QCOMPARE (errorSpy[0][0].toString (), string (fatalErrorPrefix + expectedErrorString));
        } else {
            QCOMPARE (completeSpy.findItem ("B").instruction, CSYNC_INSTRUCTION_IGNORE);
            QVERIFY (completeSpy.findItem ("B").errorString.contains (expectedErrorString));

            // The other folder should have been sync'ed as the sync just ignored the faulty dir
            QCOMPARE (fakeFolder.currentRemoteState ().children["A"], fakeFolder.currentLocalState ().children["A"]);
            QCOMPARE (fakeFolder.currentRemoteState ().children["C"], fakeFolder.currentLocalState ().children["C"]);
            QCOMPARE (completeSpy.findItem ("A/z1").instruction, CSYNC_INSTRUCTION_NEW);
        }

        //
        // Check the same discovery error on the sync root
        //
        errorFolder = "dav/files/admin/";
        fatalErrorPrefix = "Server replied with an error while reading directory \"\" : ";
        errorSpy.clear ();
        QVERIFY (!fakeFolder.syncOnce ());
        QCOMPARE (errorSpy.size (), 1);
        QCOMPARE (errorSpy[0][0].toString (), string (fatalErrorPrefix + expectedErrorString));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMissingData () {
        FakeFolder fakeFolder{ FileInfo () };
        fakeFolder.remoteModifier ().insert ("good");
        fakeFolder.remoteModifier ().insert ("noetag");
        fakeFolder.remoteModifier ().find ("noetag").etag.clear ();
        fakeFolder.remoteModifier ().insert ("nofileid");
        fakeFolder.remoteModifier ().find ("nofileid").fileId.clear ();
        fakeFolder.remoteModifier ().mkdir ("nopermissions");
        fakeFolder.remoteModifier ().insert ("nopermissions/A");

        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest req, QIODevice *)
                . Soup.Reply *{
            if (req.attribute (QNetworkRequest.CustomVerbAttribute) == "PROPFIND" && req.url ().path ().endsWith ("nopermissions"))
                return new MissingPermissionsPropfindReply (fakeFolder.remoteModifier (), op, req, this);
            return null;
        });

        ItemCompletedSpy completeSpy (fakeFolder);
        QVERIFY (!fakeFolder.syncOnce ());

        QCOMPARE (completeSpy.findItem ("good").instruction, CSYNC_INSTRUCTION_NEW);
        QCOMPARE (completeSpy.findItem ("noetag").instruction, CSYNC_INSTRUCTION_ERROR);
        QCOMPARE (completeSpy.findItem ("nofileid").instruction, CSYNC_INSTRUCTION_ERROR);
        QCOMPARE (completeSpy.findItem ("nopermissions").instruction, CSYNC_INSTRUCTION_NEW);
        QCOMPARE (completeSpy.findItem ("nopermissions/A").instruction, CSYNC_INSTRUCTION_ERROR);
        QVERIFY (completeSpy.findItem ("noetag").errorString.contains ("ETag"));
        QVERIFY (completeSpy.findItem ("nofileid").errorString.contains ("file identifier"));
        QVERIFY (completeSpy.findItem ("nopermissions/A").errorString.contains ("permission"));
    }
}

QTEST_GUILESS_MAIN (TestRemoteDiscovery)