# project(
#	'com.elsiehupp.NextcloudVala',
#	'c',
#	'vala',
#	version: '1.0.0')

srcs = files([
#    'CrashReporterConfig.vala.in',
    'Main.vala'
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # libsecret-1-dev
    dependency('libsecret-1'),
    # dependency('libsoup-2.4'),
    # subproject('gpseq_lib').get_variable ('gpseq_dep')
]

crash_reporter_lib = library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)

crash_reporter_dep = declare_dependency(
    link_with: cmd_lib, 
    include_directories: include_directories('.')
)
