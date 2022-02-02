project(
	'com.elsiehupp.NextcloudVala',
	'c',
	'vala',
	version: '1.0.0')

srcs = files([
    'Asserts.vala',
    'ComputeChecksum.vala',
    'Constants.vala',
    'FileSystem.vala',
    'JenkinsHash.vala',
    'PinState.vala',
    'PluginFactory.vala',
    'PreparedSqlQueryManager.vala',
    'RemotePermissions.vala',
    'Result.vala',
    'SqlDatabase.vala',
    'SyncFileStatus.vala',
    'SyncJournalDb.vala',
    'SyncJournalFileRecord.vala',
    'Utility.vala',
    'Vfs.vala'
])

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false
)