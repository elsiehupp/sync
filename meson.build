project('com.elsiehupp.NextcloudVala', 'c', 'vala', version: '1.0.0')

srcs = files([
#    'Config.vala.in',
#    'Version.vala.in'
])

subdir('Vala')

libraries = [
    # '3rdParty',
    cmd,
    common,
    # 'CrashReporter',
    csync,
    # 'Gui',
    lib_sync,
    # 'ShellIntegration',
    # 'Testing',
]

executable(
    meson.project_name(),
    srcs,
#     dependencies: deps,
    install: false,
    link_with: libraries
)