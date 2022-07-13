srcs = files([
    'AbstractTestSyncConflict.vala',
    'TestConflictFileBaseNameData.vala',
    'TestConflictFileBaseName.vala',
    'TestConflictRecordRemoval1.vala',
    'TestConflictRecordRemoval2.vala',
    'TestDownloadingConflictFile.vala',
    'TestLocalDirectoryRemoteFileConflict.vala',
    'TestLocalFileRemoteDirectoryConflict.vala',
    'TestNoUpload.vala',
    'TestRemoveRemove.vala',
    'TestSeparateUpload.vala',
    'TestTypeChange.vala',
    'TestTypeConflictWithMove.vala',
    'TestUploadAfterDownload.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)