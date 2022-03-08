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

class TestDownload : GLib.Object {

    const int64 STOP_AFTER = 3123668;

    /***********************************************************
    ***********************************************************/
    private void testResume () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy = new QSignalSpy (fake_folder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr)));
        var size = 30 * 1000 * 1000;
        fake_folder.remote_modifier ().insert ("A/a0", size);

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                return new BrokenFakeGetReply (fake_folder.remote_modifier (), operation, request, this);
            }
            return null;
        });

        //  QVERIFY (!fake_folder.sync_once ()); // The sync must fail because not all the file was downloaded
        //  QCOMPARE (getItem (completeSpy, "A/a0").status, SyncFileItem.Status.SOFT_ERROR);
        //  QCOMPARE (getItem (completeSpy, "A/a0").errorString, string ("The file could not be downloaded completely."));
        //  QVERIFY (fake_folder.sync_engine ().isAnotherSyncNeeded ());

        // Now, we need to restart, this time, it should resume.
        GLib.ByteArray ranges;
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation && request.url ().path ().endsWith ("A/a0")) {
                ranges = request.rawHeader ("Range");
            }
            return null;
        });
        //  QVERIFY (fake_folder.sync_once ()); // now this succeeds
        //  QCOMPARE (ranges, GLib.ByteArray ("bytes=" + GLib.ByteArray.number (STOP_AFTER) + "-"));
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testErrorMessage () {
        // This test's main goal is to test that the error string from the server is shown in the UI

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().setIgnoreHiddenFiles (true);
        QSignalSpy completeSpy = new QSignalSpy (&fake_folder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        var size = 3500000;
        fake_folder.remote_modifier ().insert ("A/broken", size);

        GLib.ByteArray serverMessage = = new GLib.ByteArray ("The file was not downloaded because the tests wants so!");

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) Soup.Reply * => {
            if (operation == Soup.GetOperation && request.url ().path ().endsWith ("A/broken")) {
                return new FakeErrorReply (operation, request, this, 400,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    + "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    + "<s:exception>Sabre\\DAV\\Exception\\Forbidden</s:exception>\n"
                    + "<s:message>" + serverMessage + "</s:message>\n"
                    + "</d:error>");
            }
            return null;
        });

        bool timedOut = false;
        QTimer.singleShot (10000, fake_folder.sync_engine (), [&] () { timedOut = true; fake_folder.sync_engine ().on_signal_abort (); });
        //  QVERIFY (!fake_folder.sync_once ());  // Fail because A/broken
        //  QVERIFY (!timedOut);
        //  QCOMPARE (getItem (completeSpy, "A/broken").status, SyncFileItem.Status.NORMAL_ERROR);
        //  QVERIFY (getItem (completeSpy, "A/broken").errorString.contains (serverMessage));
    }


    /***********************************************************
    ***********************************************************/
    private void serverMaintenence () {
        // Server in maintenance must on_signal_abort the sync.

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("A/broken");
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) Soup.Reply * => {
            if (operation == Soup.GetOperation) {
                return new FakeErrorReply (operation, request, this, 503,
                    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                    + "<d:error xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\">\n"
                    + "<s:exception>Sabre\\DAV\\Exception\\ServiceUnavailable</s:exception>\n"
                    + "<s:message>System in maintenance mode.</s:message>\n"
                    + "</d:error>");
            }
            return null;
        });

        QSignalSpy completeSpy (&fake_folder.sync_engine (), &SyncEngine.itemCompleted);
        //  QVERIFY (!fake_folder.sync_once ()); // Fail because A/broken
        // FatalError means the sync was aborted, which is what we want
        //  QCOMPARE (getItem (completeSpy, "A/broken").status, SyncFileItem.Status.FATAL_ERROR);
        //  QVERIFY (getItem (completeSpy, "A/broken").errorString.contains ("System in maintenance mode"));
    }


    /***********************************************************
    ***********************************************************/
    private void testMoveFailsInAConflict () {
        // Test for https://github.com/owncloud/client/issues/7015
        // We want to test the case in which the renaming of the original to the conflict file succeeds,
        // but renaming the temporary file fails.
        // This tests uses the fact that a "touchedFile" notification will be sent at the right moment.
        // Note that there will be first a notification on the file and the conflict file before.

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().setIgnoreHiddenFiles (true);
        fake_folder.remote_modifier ().set_contents ("A/a1", 'A');
        fake_folder.local_modifier ().set_contents ("A/a1", 'B');

        bool propConnected = false;
        string conflictFile;
        var transProgress = connect (&fake_folder.sync_engine (), &SyncEngine.transmissionProgress,
                                     [] (ProgressInfo progress_info) => {
            var propagator = fake_folder.sync_engine ().getPropagator ();
            if (progress_info.status () != ProgressInfo.Status.PROPAGATION || propConnected || !propagator)
                return;
            propConnected = true;
            connect (propagator.data (), &OwncloudPropagator.touchedFile, [&] (string s) {
                if (s.contains ("conflicted copy")) {
                    //  QCOMPARE (conflictFile, "");
                    conflictFile = s;
                    return;
                }
                if (!conflictFile.isEmpty ()) {
                    // Check that the temporary file is still there
                    //  QCOMPARE (QDir (fake_folder.local_path () + "A/").entryList ({"*.~*"}, QDir.Files | QDir.Hidden).count (), 1);
                    // Set the permission to read only on the folder, so the rename of the temporary file will fail
                    GLib.File (fake_folder.local_path () + "A/").setPermissions (GLib.File.Permissions (0x5555));
                }
            });
        });

        //  QVERIFY (!fake_folder.sync_once ()); // The sync must fail because the rename failed
        //  QVERIFY (!conflictFile.isEmpty ());

        // restore permissions
        GLib.File (fake_folder.local_path () + "A/").setPermissions (GLib.File.Permissions (0x7777));

        GLib.Object.disconnect (transProgress);
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request &, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation)
                QTest.qFail ("There shouldn't be any download", __FILE__, __LINE__);
            return null;
        });
        //  QVERIFY (fake_folder.sync_once ());

        // The a1 file is still tere and have the right content
        //  QVERIFY (fake_folder.current_remote_state ().find ("A/a1"));
        //  QCOMPARE (fake_folder.current_remote_state ().find ("A/a1").content_char, 'A');

        //  QVERIFY (GLib.File.remove (conflictFile)); // So the comparison succeeds;
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void testHttp2Resend () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("A/resendme", 300);

        GLib.ByteArray serverMessage = "Needs to be resend on a new connection!";
        int resendActual = 0;
        int resendExpected = 2;

        // First, download only the first 3 MB of the file
        fake_folder.set_server_override ([&] (Soup.Operation operation, Soup.Request request, QIODevice *) . Soup.Reply * {
            if (operation == Soup.GetOperation && request.url ().path ().endsWith ("A/resendme") && resendActual < resendExpected) {
                var errorReply = new FakeErrorReply (operation, request, this, 400, "ignore this body");
                errorReply.set_error (Soup.Reply.ContentReSendError, serverMessage);
                errorReply.set_attribute (Soup.Request.HTTP2WasUsedAttribute, true);
                errorReply.set_attribute (Soup.Request.HttpStatusCodeAttribute, GLib.Variant ());
                resendActual += 1;
                return errorReply;
            }
            return null;
        });

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        //  QCOMPARE (resendActual, 2);

        fake_folder.remote_modifier ().append_byte ("A/resendme");
        resendActual = 0;
        resendExpected = 10;

        QSignalSpy completeSpy (&fake_folder.sync_engine (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
        //  QVERIFY (!fake_folder.sync_once ());
        //  QCOMPARE (resendActual, 4); // the 4th fails because it only resends 3 times
        //  QCOMPARE (getItem (completeSpy, "A/resendme").status, SyncFileItem.Status.NORMAL_ERROR);
        //  QVERIFY (getItem (completeSpy, "A/resendme").errorString.contains (serverMessage));
    }
}

QTEST_GUILESS_MAIN (TestDownload)
#include "testdownload.moc"
