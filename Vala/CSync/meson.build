# project(
#	'com.elsiehupp.NextcloudVala',
#	'c',
#	'vala',
#	version: '1.0.0')

srcs = files([
#    'ConfigCSync.vala.cmake',
    'CsyncExclude.vala',
    'Csync.vala',
#    'CsyncVersion.vala.in',
    'Std/CLib.vala',
    'Std/CPrivate.vala',
    'Std/CTime.vala',
    'Vio/CSyncVioLocal.vala'
])

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false
)