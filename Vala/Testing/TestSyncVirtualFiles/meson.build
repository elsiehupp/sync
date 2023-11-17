srcs = files([
    'AbstractTestSyncVirtualFiles.vala',
    'TestDownloadRecursive.vala',
    'TestExtraFilesWhileLocalHydrated.vala',
    'TestIncompatiblePins.vala',
    'TestNewFilesNotVirtual.vala',
    'TestNewVirtuals.vala',
    'TestPinStateLocals.vala',
    'TestPlaceholderExists.vala',
    'TestRenameToVirtual.vala',
    'TestRenameVirtual2.vala',
    'TestRenameVirtual.vala',
    'TestSuffixFilesWhileLocalHydrated.vala',
    'TestSyncDehydration.vala',
    'TestSyncVirtualFilesAvailability.vala',
    'TestVirtualFileConflict.vala',
    'TestVirtualFileDownloadResume.vala',
    'TestVirtualFileDownload.vala',
    'TestVirtualFileLifecycleData.vala',
    'TestVirtualFileLifecycle.vala',
    'TestWipeVirtualSuffixFiles.vala',
    'TestWithNormalSync.vala',
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