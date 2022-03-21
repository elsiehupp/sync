srcs = files([
    'TestCreateFileWithTrailingSpacesLocalAndRemoteTrimmedDoNotExistRenameAndUploadFile.vala',
    'TestCreateFileWithTrailingSpacesLocalTrimmedAlsoCreatedDontRenameAndUploadFile.vala',
    'TestCreateFileWithTrailingSpacesLocalTrimmedDoesExistDontRenameAndUploadFile.vala',
    'TestDirectoryAndSubDirectory.vala',
    'TestLocalDiscoveryDecision.vala',
    'TestLocalDiscoveryStyle.vala',
    'TestServerBlocklist.vala',
    'TestTrackerItemCompletion.vala',
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