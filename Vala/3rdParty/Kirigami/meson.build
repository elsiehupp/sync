srcs = files([
    'GlobalWheelFilter.vala',
    'GlobalWheelFilterSingleton.vala',
    'KirigamiWheelEvent.vala',
    'WheelHandler.vala',
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
    # libsecret-1-dev
    # dependency('libsecret-1'),
    # dependency('libsoup-2.4'),
]

libraries = [
    subproject('gpseq').get_variable ('gpseq_lib')
]

library(
    'Kirigami',
    srcs,
#     dependencies: deps,
    install: false,
    link_with: libraries
)