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
    # dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
    meson.get_compiler('vala').find_library('readline'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)