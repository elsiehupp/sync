srcs = files([
    'AbstractTestSyncJournalDB.vala',
    'TestAvoidReadFromDatabaseOnNextSync.vala',
    'TestConflictRecord.vala',
    'TestDownloadInfo.vala',
    'TestFileRecordChecksum.vala',
    'TestFileRecord.vala',
    'TestNumericId.vala',
    'TestPinState.vala',
    'TestRecursiveDelete.vala',
    'TestUploadInfo.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk4'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)