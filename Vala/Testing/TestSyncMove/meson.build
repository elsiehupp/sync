srcs = files([
    'AbstractTestSyncMove.vala',
    'TestDeepHierarchyData.vala',
    'TestDeepHierarchy.vala',
    'TestDuplicateFileIdentifierData.vala',
    'TestDuplicateFileIdentifier.vala',
    'TestInvertFolderHierarchy.vala',
    'TestLocalMoveDetection.vala',
    'TestMoveAndModTimeChange.vala',
    'TestMoveAndTypeChange.vala',
    'TestMoveCustomRemoteRoot.vala',
    'TestMovedWithErrorData.vala',
    'TestMovedWithError.vala',
    'TestMoveFileToDifferentFolderOnBothSides.vala',
    'TestMovePropagation.vala',
    'TestRemoteChangeInMovedFolder.vala',
    'TestRenameCaseOnly.vala',
    'TestRenameOnBothSides.vala',
    'TestRenameParallelism.vala',
    'TestSelectiveSyncMovedFolder.vala',
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