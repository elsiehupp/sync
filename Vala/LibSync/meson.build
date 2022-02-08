project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'AbstractPropagateRemoteDeleteEncrypted.vala',
    'AccessManager.vala',
    'AccountFwd.vala',
    'Account.vala',
    'BandwidthManager.vala',
    'BulkPropagatorJob.vala',

    'Capabilities/Capabilities.vala',
    'Capabilities/DirectEditor.vala',

    'ClientProxy/ClientProxy.vala',
    'ClientProxy/SystemProxyRunnable.vala',

    'ClientSideEncryption/Biometric.vala',
    'ClientSideEncryption/CipherContext.vala',
    'ClientSideEncryption/ClientSideEncryption.vala',
    'ClientSideEncryption/EncryptionHelper.vala',
    'ClientSideEncryption/FolderMetadata.vala',
    'ClientSideEncryption/PrivateKey.vala',
    'ClientSideEncryption/PrivateKeyContext.vala',
    'ClientSideEncryption/StreamingDecryptor.vala',
    'ClientSideEncryption/X509Certificate.vala',

    'ClientSideEncryptionJobs/DeleteMetadataApiJob.vala',
    'ClientSideEncryptionJobs/GetMetadataApiJob.vala',
    'ClientSideEncryptionJobs/LockEncryptFolderApiJob.vala',
    'ClientSideEncryptionJobs/SetEncryptionFlagApiJob.vala',
    'ClientSideEncryptionJobs/SignPublicKeyApiJob.vala',
    'ClientSideEncryptionJobs/StoreMetaDataApiJob.vala',
    'ClientSideEncryptionJobs/StorePrivateKeyApiJob.vala',
    'ClientSideEncryptionJobs/UnlockEncryptFolderApiJob.vala',
    'ClientSideEncryptionJobs/UpdateMetadataApiJob.vala',

    'ConfigFile.vala',
    'CookieJar.vala',

    'Credentials/AbstractCredentials.vala',
    'Credentials/CredentialsCommon.vala',
    'Credentials/DummyCredentials.vala',
    'Credentials/HttpCredentials.vala',
    'Credentials/HttpCredentialsAccessManager.vala',

    'Credentials/KeychainChunk/DeleteJob.vala',
    'Credentials/KeychainChunk/Job.vala',
    'Credentials/KeychainChunk/ReadJob.vala',
    'Credentials/KeychainChunk/WriteJob.vala',

    'Credentials/TokenCredentials.vala',

    'DateTimeProvider.vala',
    'DeleteJob.vala',
    'DiscoveryPhase/DiscoveryPhase.vala',
    'EncryptFolderJob.vala',
    'FileSystem.vala',
    'HttpLogger.vala',
    'IconJob.vala',
    'LocalDiscoveryTracker.vala',
    'Logger.vala',

    'NetworkJobs/AbstractNetworkJob.vala',
    'NetworkJobs/AvatarJob.vala',
    'NetworkJobs/CheckServerJob.vala',
    'NetworkJobs/DeleteApiJob.vala',
    'NetworkJobs/DetermineAuthTypeJob.vala',
    'NetworkJobs/EntityExistsJob.vala',
    'NetworkJobs/JsonApiJob.vala',
    'NetworkJobs/LsColJob.vala',
    'NetworkJobs/LsColXMLParser.vala',
    'NetworkJobs/MkColJob.vala',
    'NetworkJobs/NetworkJobs.vala',
    'NetworkJobs/PropfindJob.vala',
    'NetworkJobs/ProppatchJob.vala',
    'NetworkJobs/RequestEtagJob.vala',
    'NetworkJobs/SimpleNetworkJob.vala',

    'NextcloudTheme.vala',

    'OcsProfileConnector/Hovercard.vala',
    'OcsProfileConnector/HovercardAction.vala',
    'OcsProfileConnector/OcsProfileConnector.vala',

    'OcsUserStatusConnector.vala',

    'OwncloudPropagator/CleanupPollsJob.vala',
    'OwncloudPropagator/OwncloudPropagator.vala',
    'OwncloudPropagator/PropagateDirectory.vala',
    'OwncloudPropagator/PropagateIgnoreJob.vala',
    'OwncloudPropagator/PropagateItemJob.vala',
    'OwncloudPropagator/PropagateRootDirectory.vala',
    'OwncloudPropagator/PropagatorCompositeJob.vala',
    'OwncloudPropagator/PropagatorJob.vala',

    'ProcessDirectoryJob.vala',

    'ProgressDispatcher/ErrorCategory.vala',
    'ProgressDispatcher/ProgressDispatcher.vala',
    'ProgressDispatcher/ProgressInfo.vala',

    'PropagateDownload/GETEncryptedFileJob.vala',
    'PropagateDownload/GETFileJob.vala',
    'PropagateDownload/PropagateDownloadFile.vala',

    'PropagateDownloadEncrypted.vala',
    'PropagateRemoteDeleteEncryptedRootFolder.vala',
    'PropagateRemoteDeleteEncrypted.vala',
    'PropagateRemoteDelete.vala',
    'PropagateRemoteMkdir.vala',

    'PropagateRemoteMove/MoveJob.vala',
    'PropagateRemoteMove/PropagateRemoteMove.vala',

    'PropagateUpload/PollJob.vala',
    'PropagateUpload/PropagateUploadFileCommon.vala',
    'PropagateUpload/PropagateUploadFileNG.vala',
    'PropagateUpload/PropagateUploadFileV1.vala',
    'PropagateUpload/PropagateUploadNg.vala',
    'PropagateUpload/PropagateUploadV1.vala',
    'PropagateUpload/PUTFileJob.vala',
    'PropagateUpload/UploadDevice.vala',

    'PropagateUploadEncrypted.vala',

    'PropagatorJobs/PropagateLocalMkdir.vala',
    'PropagatorJobs/PropagateLocalRemove.vala',
    'PropagatorJobs/PropagateLocalRename.vala',
    'PropagatorJobs/PropagatorJobs.vala',

    'PushNotifications.vala',
    'PutMultiFileJob.vala',
    'SyncEngine.vala',
    'SyncFileItem.vala',
    'SyncFileStatusTracker.vala',
    'SyncOptions.vala',
    'SyncResult.vala',
    'Theme.vala',

    'UserStatus/ClearAt.vala',
    'UserStatus/UserStatusConnector.vala',
    'UserStatus/UserStatus.vala',

    'Vfs/VfsSuffix/SuffixVfsPluginFactory.vala',
    'Vfs/VfsSuffix/VfsSuffix.vala',

    'Vfs/VfsXAttr/VfsXAttr.vala',
    'Vfs/VfsXAttr/XattrVfsPluginFactory.vala',
    'Vfs/VfsXAttr/XAttrWrapper.vala',

    'WordList.vala'
])

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false
)