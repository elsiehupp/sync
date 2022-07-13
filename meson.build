project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
#    'Config.vala.in',
#    'Version.vala.in'
])

subdir('Vala')

libraries = [
    # subproject('3rd_party').get_variable ('3rd_party'),
    subproject('cmd').get_variable ('cmd'),
    subproject('common').get_variable ('common'),
    # 'CrashReporter',
    subproject('csync').get_variable ('csync'),
    # 'Gui',
    subproject('lib_sync').get_variable ('lib_sync'),
    # 'ShellIntegration',
    # 'Testing',
    subproject('gpseq_lib').get_variable ('gpseq_lib')
]

executable(
    meson.project_name(),
    srcs,
    # dependencies: deps,
    install: false,
    link_with: libraries
)