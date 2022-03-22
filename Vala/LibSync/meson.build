# project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'Account.vala',
    'BandwidthManager.vala',

    'Capabilities/Capabilities.vala',
    'Capabilities/DirectEditor.vala',

    'ClientProxy/ClientProxy.vala',
    'ClientProxy/SystemProxyRunnable.vala',

    'ClientSideEncryption/Biometric.vala',
    'ClientSideEncryption/CipherContext.vala',
    'ClientSideEncryption/ClientSideEncryption.vala',
    'ClientSideEncryption/EncryptedFile.vala',
    'ClientSideEncryption/EncryptionHelper.vala',
    'ClientSideEncryption/FolderMetadata.vala',
    'ClientSideEncryption/PrivateKeyContext.vala',
    'ClientSideEncryption/PrivateKey.vala',
    'ClientSideEncryption/StreamingDecryptor.vala',
    'ClientSideEncryption/X509Certificate.vala',

    'ClientSideEncryptionJobs/DeleteMetadataApiJob.vala',
    'ClientSideEncryptionJobs/GetMetadataApiJob.vala',
    'ClientSideEncryptionJobs/LockEncryptFolderApiJob.vala',
    'ClientSideEncryptionJobs/SetEncryptionFlagApiJob.vala',
    'ClientSideEncryptionJobs/SignPublicKeyApiJob.vala',
    'ClientSideEncryptionJobs/StoreMetadataApiJob.vala',
    'ClientSideEncryptionJobs/StorePrivateKeyApiJob.vala',
    'ClientSideEncryptionJobs/UnlockEncryptFolderApiJob.vala',
    'ClientSideEncryptionJobs/UpdateMetadataApiJob.vala',

    'ConfigFile.vala',

    'Credentials/AbstractCredentials.vala',
    'Credentials/DummyCredentials.vala',
    'Credentials/HttpCredentials.vala',
    'Credentials/TokenCredentials.vala',

    'DiscoveryPhase/DiscoveryPhase.vala',
    'DiscoveryPhase/DiscoverySingleDirectoryJob.vala',
    'DiscoveryPhase/DiscoverySingleLocalDirectoryJob.vala',
    'DiscoveryPhase/LocalInfo.vala',
    'DiscoveryPhase/RemoteInfo.vala',

    'EtagParser.vala',
    'ExtraFolderInfo.vala',
    'FileSystem.vala',
    'HttpError.vala',
    'HttpLogger.vala',
    'IconJob.vala',

    'LocalDiscoveryTracker.vala',
    'Logger.vala',
    'LsColXMLParser.vala',

    'NetworkJobs/AbstractNetworkJob.vala',
    'NetworkJobs/AvatarJob.vala',
    'NetworkJobs/CheckServerJob.vala',
    'NetworkJobs/DeleteApiJob.vala',
    'NetworkJobs/DetermineAuthTypeJob.vala',
    'NetworkJobs/EncryptFolderJob.vala',
    'NetworkJobs/EntityExistsJob.vala',
    'NetworkJobs/GETEncryptedFileJob.vala',
    'NetworkJobs/GETFileJob.vala',
    'NetworkJobs/JsonApiJob.vala',
    'NetworkJobs/KeychainChunkDeleteJob-1.vala',

    'NetworkJobs/KeychainChunkJob/AbstractKeychainChunkJob.vala',
    'NetworkJobs/KeychainChunkJob/KeychainChunkDeleteJob.vala',
    'NetworkJobs/KeychainChunkJob/KeychainChunkReadJob.vala',
    'NetworkJobs/KeychainChunkJob/KeychainChunkWriteJob.vala',

    'NetworkJobs/LsColJob.vala',
    'NetworkJobs/MkColJob.vala',
    'NetworkJobs/MoveJob.vala',
    'NetworkJobs/PollJob.vala',
    'NetworkJobs/PropagateDownloadFile.vala',

    'NetworkJobs/PropagatorJob/AbstractPropagatorJob.vala',
    'NetworkJobs/PropagatorJob/BulkPropagatorJob.vala',

    'NetworkJobs/PropagatorJob/PropagateDirectory.vala',

    'NetworkJobs/PropagatorJob/PropagateItemJob/AbstractPropagateItemJob.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateIgnoreJob.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateLocalMkdir.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateLocalRemove.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateLocalRename.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateRemoteDelete.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateRemoteMkdir.vala',
    'NetworkJobs/PropagatorJob/PropagateItemJob/PropagateRemoteMove.vala',

    'NetworkJobs/PropagatorJob/PropagateRemoteDeleteEncrypted/AbstractPropagateRemoteDeleteEncrypted.vala',
    'NetworkJobs/PropagatorJob/PropagateRemoteDeleteEncrypted/PropagateRemoteDeleteEncryptedRootFolder.vala',
    'NetworkJobs/PropagatorJob/PropagateRemoteDeleteEncrypted/PropagateRemoteDeleteEncrypted.vala',

    'NetworkJobs/PropagatorJob/PropagateRootDirectory.vala',
    'NetworkJobs/PropagatorJob/PropagateUploadCommon.vala',
    'NetworkJobs/PropagatorJob/PropagateUploadEncrypted.vala',
    'NetworkJobs/PropagatorJob/PropagateUploadNg.vala',
    'NetworkJobs/PropagatorJob/PropagateUploadV1.vala',
    'NetworkJobs/PropagatorJob/PropagatorCompositeJob.vala',
    'NetworkJobs/PropagatorJob/PUTFileJob.vala',

    'NetworkJobs/PropfindJob.vala',
    'NetworkJobs/ProppatchJob.vala',
    'NetworkJobs/PutMultiFileJob.vala',
    'NetworkJobs/RequestEtagJob.vala',
    'NetworkJobs/SimpleNetworkJob.vala',

    'OwncloudPropagator/CleanupPollsJob.vala',
    'OwncloudPropagator/OwncloudPropagator.vala',
    'OwncloudPropagator/PropagateDownloadEncrypted.vala',

    'ProcessDirectoryJob.vala',

    'ProgressDispatcher/ErrorCategory.vala',
    'ProgressDispatcher/ProgressDispatcher.vala',
    'ProgressDispatcher/ProgressInfo.vala',

    'PushNotificationManager.vala',

    'Soup/AccessManager.vala',
    'Soup/CookieJar.vala',
    'Soup/HttpCredentialsAccessManager.vala',
    'Soup/TokenCredentialsAccessManager.vala',

    'SyncEngine.vala',
    'SyncFileItem.vala',
    'SyncFileStatusTracker.vala',
    'SyncOptions.vala',
    'SyncResult.vala',

    'Theme/AbstractTheme.vala',
    'Theme/NextcloudTheme.vala',

    'UploadDevice.vala',

    'UserStatus/AbstractUserStatusConnector.vala',
    'UserStatus/ClearAt.vala',

    'UserStatus/OcsProfileConnector/HovercardAction.vala',
    'UserStatus/OcsProfileConnector/Hovercard.vala',
    'UserStatus/OcsProfileConnector/OcsProfileConnector.vala',

    'UserStatus/OcsUserStatusConnector.vala',
    'UserStatus/UserStatus.vala',

    'Vfs/VfsSuffix/SuffixVfsPluginFactory.vala',
    'Vfs/VfsSuffix/VfsSuffix.vala',

    'Vfs/VfsXAttr/VfsXAttr.vala',
    'Vfs/VfsXAttr/XattrVfsPluginFactory.vala',
    'Vfs/VfsXAttr/XAttrWrapper.vala',

    'WordList.vala'
])

# Dependences
deps = [
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    # gnutls-dev
    dependency('gnutls'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)