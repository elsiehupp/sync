project('com.elsiehupp.NextcloudVala.Cmd', 'c', 'vala', version: '1.0.0')

srcs = files([
    'CommandLine.vala',
    'EchoDisabler.vala',
    'HttpCredentialsText.vala',
    'NetrcParser.vala',
    'SimpleSslErrorHandler.vala'
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # libjson-glib-dev
    dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
    # libsqlite3-dev
    dependency('sqlite3'),
    meson.get_compiler('vala').find_library('readline'),
    # subproject('3rd_party').get_variable ('3rd_party_dep'),
    # subproject('cmd').get_variable ('cmd_dep'),
    subproject('common').get_variable ('common_dep'),
    # 'CrashReporter',
    subproject('csync').get_variable ('csync_dep'),
    # 'Gui',
    subproject('lib_sync').get_variable ('lib_sync_dep'),
    # 'ShellIntegration',
    # 'Testing',
    # subproject('gpseq_lib').get_variable ('gpseq_dep')
]

cmd_lib = library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)

cmd_dep = declare_dependency(
    link_with: cmd_lib, 
    include_directories: include_directories('.')
)
