project('com.elsiehupp.NextcloudVala.CSync', 'c', 'vala', version: '1.0.0')

srcs = files([
#    'Config.vala.cmake',
    'ExcludedFiles.vala',
    'FileStat.vala',
    'IndividualFileStatus.vala',
    'ItemType.vala',
#    'Version.vala.in',
    'Private.vala',
    'SyncInstructions.vala',
    'SyncStatus.vala',
    'Time.vala',
    'VioHandle.vala'
])

# Dependences
deps = [
    meson.get_compiler('vala').find_library('posix'),
    dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # gnutls-dev
    # dependency('gnutls'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
    subproject('common').get_variable ('common_dep'),
    # subproject('gpseq_lib').get_variable ('gpseq_dep')
]

csync_lib = library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)

csync_dep = declare_dependency(
    link_with: csync_lib, 
    include_directories: include_directories('.')
)
