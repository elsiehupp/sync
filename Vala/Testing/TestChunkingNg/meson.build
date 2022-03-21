srcs = files([
    'AbstractTestChunkingNg.vala',
    'TestCreateConflictWhileSyncing.vala',
    'TestFileUpload.vala',
    'TestLateAbortHard.vala',
    'TestLateAbortRecoverable.vala',
    'TestModifyLocalFileWhileUploading.vala',
    'TestPercentEncoding.vala',
    'TestRemoveStale1.vala',
    'TestRemoveStale2.vala',
    'TestResume1.vala',
    'TestResume2.vala',
    'TestResume3.vala',
    'TestResume4.vala',
    'TestResumeServerDeletedChunks.vala',
    'TestVeryBigFiles.vala',
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
    install: false
)