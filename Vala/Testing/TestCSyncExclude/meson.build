srcs = files([
    'AbstractTestCSyncExclude.vala',
    'TestAddExcludeFilePathAddDefaultExcludeFileReturnCorrectMap.vala',
    'TestAddExcludeFilePathAddDifferentFilePathsListSizeDoesIncrease.vala',
    'TestAddExcludeFilePathAddSameFilePathListSizeDoesNotIncrease.vala',
    'TestCSyncBNameTrigger.vala',
    'TestCSyncDirectoryOnly.vala',
    'TestCSyncExcludeAddPerDirectory.vala',
    'TestCSyncExcludeAdd.vala',
    'TestCSyncExcludedPerDir.vala',
    'TestCSyncExcludedPerformance1.vala',
    'TestCSyncExcludedPerformance2.vala',
    'TestCSyncExcludedTraversalPerDirectory.vala',
    'TestCSyncExcludedTraversal.vala',
    'TestCSyncExcludeExpandEscapes.vala',
    'TestCSyncExclude.vala',
    'TestCSyncIsWindowsReservedWord.vala',
    'TestCSyncPaths.vala',
    'TestCSyncRegexTraversal.vala',
    'TestCSyncVersionDirective.vala',
    'TestCSyncWildcards.vala',
    'TestFun.vala',
    'TestReloadExcludeFilesFileDoesExistReturnTrue.vala',
    'TestReloadExcludeFilesFileDoesNotExistReturnFalse.vala',
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