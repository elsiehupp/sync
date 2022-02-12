# project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'Asserts.vala',

    'ComputeChecksum/ComputeChecksum.vala',
    'ComputeChecksum/ComputeChecksumBase.vala',
    'ComputeChecksum/CSyncChecksumHook.vala',
    'ComputeChecksum/ValidateChecksumHeader.vala',

    'Constants.vala',
    'FileSystem.vala',
    'JenkinsHash.vala',
    'PinState.vala',

    'PluginFactory/PluginFactory.vala',
    'PluginFactory/DefaultPluginFactory.vala',

    'PreparedSqlQueryManager.vala',
    'RemotePermissions.vala',

    'Result/Optional.vala',
    'Result/Result.vala',

    'SqlDatabase.vala',
    'SyncFileStatus.vala',
    'SyncJournalDb.vala',

    'SyncJournalFileRecord/ConflictRecord.vala',
    'SyncJournalFileRecord/SyncJournalErrorBlocklistRecord.vala',
    'SyncJournalFileRecord/SyncJournalFileRecord.vala',

    'Utility.vala',
    'Vfs.vala'
])

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false
)