srcs = files([
    'AbstractTestChecksumValidator.vala',
    'TestDownloadChecksummingAdler.vala',
    'TestMd5Calc.vala',
    'TestSha1Calc.vala',
    'TestUploadChecksummingAdler.vala',
    'TestUploadChecksummingMd5.vala',
    'TestUploadChecksummingSha1.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk4'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)