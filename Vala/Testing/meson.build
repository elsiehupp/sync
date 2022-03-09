project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'Benchmarks/BenchLargeSync.vala',

    'CSync/CommandLine.vala',
    'CSync/CheckStdCJhash.vala',
    'CSync/Torture.vala',
    'CSync/CheckVioExt.vala',

    'MockServer/HttpServer.vala',
    'MockServer/Main.vala',

    'PushNotificationsTestUtils/CredentialsStub.vala',
    'PushNotificationsTestUtils/FakeWebSocketServer.vala',

    'StubFolderMan.vala',
    'StubRemoteWipe.vala',

    'SyncEngineTestUtils/DelayedReply.vala',
    'SyncEngineTestUtils/DiskFileModifier.vala',
    'SyncEngineTestUtils/FakeChunkMoveReply.vala',
    'SyncEngineTestUtils/FakeCredentials.vala',
    'SyncEngineTestUtils/FakeDeleteReply.vala',
    'SyncEngineTestUtils/FakeErrorReply.vala',
    'SyncEngineTestUtils/FakeFolder.vala',
    'SyncEngineTestUtils/FakeGetReply.vala',
    'SyncEngineTestUtils/FakeGetWithDataReply.vala',
    'SyncEngineTestUtils/FakeHangingReply.vala',
    'SyncEngineTestUtils/FakeJsonErrorReply.vala',
    'SyncEngineTestUtils/FakeMkcolReply.vala',
    'SyncEngineTestUtils/FakeMoveReply.vala',
    'SyncEngineTestUtils/FakeMoveReply.vala',
    'SyncEngineTestUtils/FakePayloadReply.vala',
    'SyncEngineTestUtils/FakePropfindReply.vala',
    'SyncEngineTestUtils/FakePutMultiFileReply.vala',
    'SyncEngineTestUtils/FakePutReply.vala',
    'SyncEngineTestUtils/FakeQNAM.vala',
    'SyncEngineTestUtils/FakeReply.vala',
    'SyncEngineTestUtils/FileInfo.vala',
    'SyncEngineTestUtils/FileModifier.vala',
    'SyncEngineTestUtils/ItemCompletedSpy.vala',
    'SyncEngineTestUtils/PathComponents.vala',
    'SyncEngineTestUtils/SyncEngineTestUtils.vala',

    'TestAccount.vala',
    'TestAllFilesDeleted.vala',

    'TestAsyncOp/FakeAsyncReply.vala',
    'TestAsyncOp/TestAsyncOp.vala',

    'TestBlocklist.vala',
    'TestCapabilities.vala',
    'TestChecksumValidator.vala',
    'TestChunkingNg.vala',
    'TestClientSideEncryption.vala',
    'TestConcatUrl.vala',
    'TestCookies.vala',
    'TestDatabaseError.vala',

    'TestDownload/BrokenFakeGetReply.vala',
    'TestDownload/TestDownload.vala',

    'TestExcludedFiles.vala',
    'TestFolderMan.vala',
    'TestFolder.vala',
    'TestFolderWatcher.vala',
    'TestHelper.vala',
    'TestIconUtils.vala',
    'TestInotifyWatcher.vala',
    'TestLocalDiscovery.vala',
    'TestNetrcParser.vala',
    'TestNextcloudPropagator.vala',
    'TestNotificationCache.vala',

    'TestOAuth/DesktopServiceHook.vala',
    'TestOAuth/FakePostReply.vala',
    'TestOAuth/OAuthTestCase.vala',
    'TestOAuth/SlowFakePostReply.vala',
    'TestOAuth/TestOAuth.vala',

    'TestOwnSql.vala',
    'TestPermissions.vala',
    'TestPushNotifications.vala',
    'TestRemoteDiscovery.vala',
    'TestRemoteWipe.vala',
    'TestSelectiveSync.vala',

    'TestSetUserStatusDialog/FakeDateTimeProvider.vala',
    'TestSetUserStatusDialog/FakeUserStatusConnector.vala',
    'TestSetUserStatusDialog/TestSetUserStatusDialog.vala',

    'TestSyncCfapi.vala',
    'TestSyncConflict.vala',
    'TestSyncDelete.vala',
    'TestSyncEngine.vala',
    'TestSyncFileItem.vala',

    'TestSyncFileStatusTracker/StatusPushSpy.vala',
    'TestSyncFileStatusTracker/TestSyncFileStatusTracker.vala',

    'TestSyncJournalDB.vala',
    'TestSyncMove.vala',
    'TestSyncVirtualFiles.vala',
    'TestSyncXattr.vala',
    'TestTheme.vala',

    'TestUnifiedSearchListModel/FakeDesktopServicesUrlHandler.vala',
    'TestUnifiedSearchListModel/FakeProvider.vala',
    'TestUnifiedSearchListModel/FakeSearchResultsStorage.vala',
    'TestUnifiedSearchListModel/TestUnifiedSearchListModel.vala',

    'TestUpdater.vala',
    'TestUploadReset.vala',
    'TestUtility.vala',
    'TestXmlParse.vala',
    'ThemeUtils.vala'
])

# Dependences
deps = [
    dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false
)