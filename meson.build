project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
#    'Config.vala.in',
#    'Version.vala.in'
])

subdir('Vala')

deps = [
    # subproject('3rd_party').get_variable ('3rd_party_dep'),
    subproject('cmd').get_variable ('cmd_dep'),
    subproject('common').get_variable ('common_dep'),
    # 'CrashReporter',
    subproject('csync').get_variable ('csync_dep'),
    # 'Gui',
    subproject('lib_sync').get_variable ('lib_sync_dep'),
    # 'ShellIntegration',
    # 'Testing',
    # subproject('gpseq_lib').get_variable ('gpseq_dep')
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)