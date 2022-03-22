# project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
    'Asserts.vala',

    'ComputeChecksum/AbstractComputeChecksum.vala',
    'ComputeChecksum/ComputeChecksum.vala',
    'ComputeChecksum/CSyncChecksumHook.vala',
    'ComputeChecksum/ValidateChecksumHeader.vala',

    'Constants.vala',

    'Errors/InvalidParameterError.vala',

    'FileSystem.vala',
    'JenkinsHash.vala',

    'PluginFactory/AbstractPluginFactory.vala',
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

    'Vfs/AbstractVfs.vala',
    'Vfs/ItemAvailability.vala',
    'Vfs/PinState.vala',
    'Vfs/SetupParameters.vala',
    'Vfs/VfsOff.vala'
])

# Dependences
deps = [
    dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)