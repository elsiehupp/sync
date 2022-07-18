srcs = files([
    'QTokenizer.vala',
    'QStringTokenizer.vala',
    'Test/TestQTokenizer.vala',
])

deps = [
    # subproject('gpseq_lib').get_variable ('gpseq_dep')
]

library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: true
)