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

cmd = library(
    'Cmd',
    srcs,
    dependencies: deps,
    install: false
)