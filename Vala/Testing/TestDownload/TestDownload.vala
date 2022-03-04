/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>
//  #include <owncloudpropagator.h>

using Occ;

namespace Testing {

const int64 STOP_AFTER = 3'123'668;


class TestDownload : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private on_ void testResume () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy (&fakeFolder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        var size = 30 * 1000 * 1000;
        fakeFolder.remote_modifier ().insert ("A/a0", size);

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                return new BrokenFakeGetReply (fakeFolder.remote_modifier (), operation, request, this);
            }
            return null;
        });

        QVERIFY (!fakeFolder.sync_once ()); // The sync must fail because not all the file was downloaded
        QCOMPARE (getItem (completeSpy, "A/a0").status, SyncFileItem.Status.SOFT_ERROR);
        QCOMPARE (getItem (completeSpy, "A/a0").errorString, string ("The file could not be downloaded completely."));
        QVERIFY (fakeFolder.sync_engine ().isAnotherSyncNeeded ());

        // Now, we need to restart, this time, it should resume.
        GLib.ByteArray ranges;
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                ranges = request.rawHeader ("Range");
            }
            return null;
        });
        QVERIFY (fakeFolder.sync_once ()); // now this succeeds
        QCOMPARE (ranges, GLib.ByteArray ("bytes=" + GLib.ByteArray.number (STOP_AFTER) + "-"));
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testErrorMessage () {
        // This test's main goal is to test that the error string from the server is shown in the UI

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy (&fakeFolder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        var size = 3'500'000;
        fakeFolder.remote_modifier ().insert ("A/broken", size);

        GLib.ByteArray serverMessage = "The file was not downloaded because the tests wants so!";

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/broken")) {
                return new FakeErrorReply (operation, request, this, 400,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    "<s:exception>Sabre\\DAV\\Exception\\Forbidden</s:exception>\n"
                    "<s:message>"+serverMessage+"</s:message>\n"
                    "</d:error>");
            }
            return null;
        });

        bool timedOut = false;
        QTimer.singleShot (10000, fakeFolder.sync_engine (), [&] () { timedOut = true; fakeFolder.sync_engine ().on_signal_abort (); });
        QVERIFY (!fakeFolder.sync_once ());  // Fail because A/broken
        QVERIFY (!timedOut);
        QCOMPARE (getItem (completeSpy, "A/broken").status, SyncFileItem.Status.NORMAL_ERROR);
        QVERIFY (getItem (completeSpy, "A/broken").errorString.contains (serverMessage));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void serverMaintenence () {
        // Server in maintenance must on_signal_abort the sync.

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remote_modifier ().insert ("A/broken");
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation) {
                return new FakeErrorReply (operation, request, this, 503,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    "<s:exception>Sabre\\DAV\\Exception\\ServiceUnavailable</s:exception>\n"
                    "<s:message>System in maintenance mode.</s:message>\n"
                    "</d:error>");
            }
            return null;
        });

        QSignalSpy completeSpy (&fakeFolder.sync_engine (), &SyncEngine.itemCompleted);
        QVERIFY (!fakeFolder.sync_once ()); // Fail because A/broken
        // FatalError means the sync was aborted, which is what we want
        QCOMPARE (getItem (completeSpy, "A/broken").status, SyncFileItem.Status.FATAL_ERROR);
        QVERIFY (getItem (completeSpy, "A/broken").errorString.contains ("System in maintenance mode"));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testMoveFailsInAConflict () {
        // Test for https://github.com/owncloud/client/issues/7015
        // We want to test the case in which the renaming of the original to the conflict file succeeds,
        // but renaming the temporary file fails.
        // This tests uses the fact that a "touchedFile" notification will be sent at the right moment.
        // Note that there will be first a notification on the file and the conflict file before.

        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 ());
        fakeFolder.sync_engine ().setIgnoreHiddenFiles (true);
        fakeFolder.remote_modifier ().set_contents ("A/a1", 'A');
        fakeFolder.local_modifier ().set_contents ("A/a1", 'B');

        bool propConnected = false;
        string conflictFile;
        var transProgress = connect (&fakeFolder.sync_engine (), &SyncEngine.transmissionProgress,
                                     [&] (ProgressInfo pi) {
            var propagator = fakeFolder.sync_engine ().getPropagator ();
            if (pi.status () != ProgressInfo.Status.PROPAGATION || propConnected || !propagator)
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
                    QCOMPARE (QDir (fakeFolder.local_path () + "A/").entryList ({"*.~*"}, QDir.Files | QDir.Hidden).count (), 1);
                    // Set the permission to read only on the folder, so the rename of the temporary file will fail
                    GLib.File (fakeFolder.local_path () + "A/").setPermissions (GLib.File.Permissions (0x5555));
                }
            });
        });

        QVERIFY (!fakeFolder.sync_once ()); // The sync must fail because the rename failed
        QVERIFY (!conflictFile.isEmpty ());

        // restore permissions
        GLib.File (fakeFolder.local_path () + "A/").setPermissions (GLib.File.Permissions (0x7777));

        GLib.Object.disconnect (transProgress);
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request &, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation)
                QTest.qFail ("There shouldn't be any download", __FILE__, __LINE__);
            return null;
        });
        QVERIFY (fakeFolder.sync_once ());

        // The a1 file is still tere and have the right content
        QVERIFY (fakeFolder.current_remote_state ().find ("A/a1"));
        QCOMPARE (fakeFolder.current_remote_state ().find ("A/a1").content_char, 'A');

        QVERIFY (GLib.File.remove (conflictFile)); // So the comparison succeeds;
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testHttp2Resend () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remote_modifier ().insert ("A/resendme", 300);

        GLib.ByteArray serverMessage = "Needs to be resend on a new connection!";
        int resendActual = 0;
        int resendExpected = 2;

        // First, download only the first 3 MB of the file
        fakeFolder.setServerOverride ([&] (QNetworkAccessManager.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == QNetworkAccessManager.GetOperation && request.url ().path ().endsWith ("A/resendme") && resendActual < resendExpected) {
                var errorReply = new FakeErrorReply (operation, request, this, 400, "ignore this body");
                errorReply.setError (Soup.Reply.ContentReSendError, serverMessage);
                errorReply.setAttribute (Soup.Request.HTTP2WasUsedAttribute, true);
                errorReply.setAttribute (Soup.Request.HttpStatusCodeAttribute, GLib.Variant ());
                resendActual += 1;
                return errorReply;
            }
            return null;
        });

        QVERIFY (fakeFolder.sync_once ());
        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
        QCOMPARE (resendActual, 2);

        fakeFolder.remote_modifier ().append_byte ("A/resendme");
        resendActual = 0;
        resendExpected = 10;

        QSignalSpy completeSpy (&fakeFolder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        QVERIFY (!fakeFolder.sync_once ());
        QCOMPARE (resendActual, 4); // the 4th fails because it only resends 3 times
        QCOMPARE (getItem (completeSpy, "A/resendme").status, SyncFileItem.Status.NORMAL_ERROR);
        QVERIFY (getItem (completeSpy, "A/resendme").errorString.contains (serverMessage));
    }
}

QTEST_GUILESS_MAIN (TestDownload)
#include "testdownload.moc"
