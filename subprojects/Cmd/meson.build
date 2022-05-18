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
]

libraries = [
    # subproject('3rdParty').get_variable ('3rd_party'),
    # subproject('Cmd').get_variable ('cmd'),
    subproject('Common').get_variable ('common'),
    # 'CrashReporter',
    subproject('CSync').get_variable ('csync'),
    # 'Gui',
    subproject('LibSync').get_variable ('lib_sync'),
    # 'ShellIntegration',
    # 'Testing',
    subproject('Gpseq').get_variable ('gpseq_lib')
]

cmd = library(
    'Cmd',
    srcs,
    dependencies: deps,
    install: false,
    link_with: libraries
)