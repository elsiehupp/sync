# project(
#	'com.elsiehupp.NextcloudVala',
#	'c',
#	'vala',
#	version: '1.0.0')

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
    # dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # gnutls-dev
    # dependency('gnutls'),
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