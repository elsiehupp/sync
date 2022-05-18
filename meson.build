project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
#    'Config.vala.in',
#    'Version.vala.in'
])

subdir('Vala')

libraries = [
    # subproject('3rdParty').get_variable ('3rd_party'),
    subproject('Cmd').get_variable ('cmd'),
    subproject('Common').get_variable ('common'),
    # 'CrashReporter',
    subproject('CSync').get_variable ('csync'),
    # 'Gui',
    subproject('LibSync').get_variable ('lib_sync'),
    # 'ShellIntegration',
    # 'Testing',
    subproject('Gpseq').get_variable ('gpseq_lib')
]

executable(
    meson.project_name(),
    srcs,
    # dependencies: deps,
    install: false,
    link_with: libraries
)