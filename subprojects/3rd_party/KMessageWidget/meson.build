srcs = files([
    'KMessageWidget.vala',
    'KMessageWidgetPrivate.vala',
])

# Dependences
deps = [
    dependency('gdk-3.0'),
    # dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # libjson-glib-dev
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
    # libsqlite3-dev
    # dependency('sqlite3'),
    # meson.get_compiler('vala').find_library('readline'),
    subproject('gpseq_lib').get_variable ('gpseq_dep')
]

library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)