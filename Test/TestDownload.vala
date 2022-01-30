/***********************************************************
   This software is in the public domain, furnished "as is", without technical
   support, and with no warranty, express or implied, as to its usefulness for
   any purpose.

***********************************************************/

// #include <QtTest>
// #include <syncengine.h>
// #include <owncloudpropagator.h>

using namespace Occ;

static constexpr int64 stopAfter = 3'123'668;

/* A FakeGetReply that sends max 'fakeSize' bytes, but whose ContentLength has the corect size */
class BrokenFakeGetReply : FakeGetReply {

    using FakeGetReply.FakeGetReply;
    public int fakeSize = stopAfter;

    /***********************************************************
    ***********************************************************/
    public int64 bytesAvailable () override {
        if (aborted)
            return 0;
        return std.min (size, fakeSize) + QIODevice.bytesAvailable (); // NOLINT : This is intended to simulare the brokeness
    }


    /***********************************************************
    ***********************************************************/
    public int64 readData (char data, int64 maxlen) override {
        int64 len = std.min (int64{ fakeSize }, maxlen);
        std.fill_n (data, len, payload);
        size -= len;
        fakeSize -= len;
        return len;
    }
};

SyncFileItemPtr getItem (QSignalSpy &spy, string path) {
    for (GLib.List<QVariant> &args : spy) {
        var item = args[0].value<SyncFileItemPtr> ();
        if (item.destination () == path)
            return item;
    }
    return {};
}

class TestDownload : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testResume () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy (&fakeFolder.syncEngine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        var size = 30 * 1000 * 1000;
        fakeFolder.remoteModifier ().insert ("A/a0", size);

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                return new BrokenFakeGetReply (fakeFolder.remoteModifier (), op, request, this);
            }
            return nullptr;
        });

        QVERIFY (!fakeFolder.syncOnce ()); // The sync must fail because not all the file was downloaded
        QCOMPARE (getItem (completeSpy, "A/a0")._status, SyncFileItem.SoftError);
        QCOMPARE (getItem (completeSpy, "A/a0")._errorString, string ("The file could not be downloaded completely."));
        QVERIFY (fakeFolder.syncEngine ().isAnotherSyncNeeded ());

        // Now, we need to restart, this time, it should resume.
        GLib.ByteArray ranges;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                ranges = request.rawHeader ("Range");
            }
            return nullptr;
        });
        QVERIFY (fakeFolder.syncOnce ()); // now this succeeds
        QCOMPARE (ranges, GLib.ByteArray ("bytes=" + GLib.ByteArray.number (stopAfter) + "-"));
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testErrorMessage () {
        // This test's main goal is to test that the error string from the server is shown in the UI

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.syncEngine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy (&fakeFolder.syncEngine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        var size = 3'500'000;
        fakeFolder.remoteModifier ().insert ("A/broken", size);

        GLib.ByteArray serverMessage = "The file was not downloaded because the tests wants so!";

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/broken")) {
                return new FakeErrorReply (op, request, this, 400,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    "<s:exception>Sabre\\DAV\\Exception\\Forbidden</s:exception>\n"
                    "<s:message>"+serverMessage+"</s:message>\n"
                    "</d:error>");
            }
            return nullptr;
        });

        bool timedOut = false;
        QTimer.singleShot (10000, &fakeFolder.syncEngine (), [&] () { timedOut = true; fakeFolder.syncEngine ().on_abort (); });
        QVERIFY (!fakeFolder.syncOnce ());  // Fail because A/broken
        QVERIFY (!timedOut);
        QCOMPARE (getItem (completeSpy, "A/broken")._status, SyncFileItem.NormalError);
        QVERIFY (getItem (completeSpy, "A/broken")._errorString.contains (serverMessage));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void serverMaintenence () {
        // Server in maintenance must on_abort the sync.

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remoteModifier ().insert ("A/broken");
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation) {
                return new FakeErrorReply (op, request, this, 503,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    "<s:exception>Sabre\\DAV\\Exception\\ServiceUnavailable</s:exception>\n"
                    "<s:message>System in maintenance mode.</s:message>\n"
                    "</d:error>");
            }
            return nullptr;
        });

        QSignalSpy completeSpy (&fakeFolder.syncEngine (), &SyncEngine.itemCompleted);
        QVERIFY (!fakeFolder.syncOnce ()); // Fail because A/broken
        // FatalError means the sync was aborted, which is what we want
        QCOMPARE (getItem (completeSpy, "A/broken")._status, SyncFileItem.FatalError);
        QVERIFY (getItem (completeSpy, "A/broken")._errorString.contains ("System in maintenance mode"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMoveFailsInAConflict () {
        // Test for https://github.com/owncloud/client/issues/7015
        // We want to test the case in which the renaming of the original to the conflict file succeeds,
        // but renaming the temporary file fails.
        // This tests uses the fact that a "touchedFile" notification will be sent at the right moment.
        // Note that there will be first a notification on the file and the conflict file before.

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.syncEngine ().setIgnoreHiddenFiles (true);
        fakeFolder.remoteModifier ().setContents ("A/a1", 'A');
        fakeFolder.localModifier ().setContents ("A/a1", 'B');

        bool propConnected = false;
        string conflictFile;
        var transProgress = connect (&fakeFolder.syncEngine (), &SyncEngine.transmissionProgress,
                                     [&] (ProgressInfo &pi) {
            var propagator = fakeFolder.syncEngine ().getPropagator ();
            if (pi.status () != ProgressInfo.Propagation || propConnected || !propagator)
                return;
            propConnected = true;
            connect (propagator.data (), &OwncloudPropagator.touchedFile, [&] (string s) {
                if (s.contains ("conflicted copy")) {
                    QCOMPARE (conflictFile, "");
                    conflictFile = s;
                    return;
                }
                if (!conflictFile.isEmpty ()) {
                    // Check that the temporary file is still there
                    QCOMPARE (QDir (fakeFolder.localPath () + "A/").entryList ({"*.~*"}, QDir.Files | QDir.Hidden).count (), 1);
                    // Set the permission to read only on the folder, so the rename of the temporary file will fail
                    GLib.File (fakeFolder.localPath () + "A/").setPermissions (GLib.File.Permissions (0x5555));
                }
            });
        });

        QVERIFY (!fakeFolder.syncOnce ()); // The sync must fail because the rename failed
        QVERIFY (!conflictFile.isEmpty ());

        // restore permissions
        GLib.File (fakeFolder.localPath () + "A/").setPermissions (GLib.File.Permissions (0x7777));

        GLib.Object.disconnect (transProgress);
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation)
                QTest.qFail ("There shouldn't be any download", __FILE__, __LINE__);
            return nullptr;
        });
        QVERIFY (fakeFolder.syncOnce ());

        // The a1 file is still tere and have the right content
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QCOMPARE (fakeFolder.currentRemoteState ().find ("A/a1").contentChar, 'A');

        QVERIFY (GLib.File.remove (conflictFile)); // So the comparison succeeds;
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testHttp2Resend () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remoteModifier ().insert ("A/resendme", 300);

        GLib.ByteArray serverMessage = "Needs to be resend on a new connection!";
        int resendActual = 0;
        int resendExpected = 2;

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation op, QNetworkRequest &request, QIODevice *) . QNetworkReply * {
            if (op == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/resendme") && resendActual < resendExpected) {
                var errorReply = new FakeErrorReply (op, request, this, 400, "ignore this body");
                errorReply.setError (QNetworkReply.ContentReSendError, serverMessage);
                errorReply.setAttribute (QNetworkRequest.HTTP2WasUsedAttribute, true);
                errorReply.setAttribute (QNetworkRequest.HttpStatusCodeAttribute, QVariant ());
                resendActual += 1;
                return errorReply;
            }
            return nullptr;
        });

        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (resendActual, 2);

        fakeFolder.remoteModifier ().appendByte ("A/resendme");
        resendActual = 0;
        resendExpected = 10;

        QSignalSpy completeSpy (&fakeFolder.syncEngine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        QVERIFY (!fakeFolder.syncOnce ());
        QCOMPARE (resendActual, 4); // the 4th fails because it only resends 3 times
        QCOMPARE (getItem (completeSpy, "A/resendme")._status, SyncFileItem.NormalError);
        QVERIFY (getItem (completeSpy, "A/resendme")._errorString.contains (serverMessage));
    }
};

QTEST_GUILESS_MAIN (TestDownload)
#include "testdownload.moc"
