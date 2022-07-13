project('com.elsiehupp.NextcloudVala.Common', 'c', 'vala', version: '1.0.0')

srcs = files([
    'Asserts.vala',

    'ComputeChecksum/AbstractComputeChecksum.vala',
    'ComputeChecksum/ComputeChecksum.vala',
    'ComputeChecksum/CSyncChecksumHook.vala',
    'ComputeChecksum/ValidateChecksumHeader.vala',

    'Config.vala',
    'Constants.vala',

    'Errors/InvalidParameterError.vala',

    'FileSystem.vala',
    'JenkinsHash.vala',

    'PluginFactory/AbstractPluginFactory.vala',
    'PluginFactory/DefaultPluginFactory.vala',

    'PreparedSqlQuery.vala',
    'PreparedSqlQueryManager.vala',
    'RemotePermissions.vala',

    'Result/Result.vala',

    'SqlDatabase.vala',
    'SqlQuery.vala',
    'SyncFileStatus.vala',
    'SyncJournalDb.vala',

    'SyncJournalFileRecord/ConflictRecord.vala',
    'SyncJournalFileRecord/SyncJournalErrorBlocklistRecord.vala',
    'SyncJournalFileRecord/SyncJournalFileRecord.vala',

    'Utility.vala',
    'Version.vala',

    'Vfs/AbstractVfs.vala',
    'Vfs/ItemAvailability.vala',
    'Vfs/PinState.vala',
    'Vfs/SetupParameters.vala',
    'Vfs/VfsMode.vala',
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
    # libsqlite3-dev
    dependency('sqlite3'),
    dependency('zlib'),
]

libraries = [
    # subproject('3rd_party').get_variable ('3rd_party'),
    # subproject('cmd').get_variable ('cmd'),
    # subproject('common').get_variable ('common'),
    # 'CrashReporter',
    subproject('csync').get_variable ('csync'),
    # 'Gui',
    # subproject('lib_sync').get_variable ('lib_sync'),
    # 'ShellIntegration',
    # 'Testing',
    subproject('gpseq_lib').get_variable ('gpseq_lib')
]

common = library(
    'common',
    srcs,
    dependencies: deps,
    install: false,
    link_with: libraries
)