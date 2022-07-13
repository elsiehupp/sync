srcs = files([
    'QProgressIndicator.vala',
])

libraries = [
    subproject('gpseq_lib').get_variable ('gpseq_lib')
]

library(
    'QProgressIndicator',
    srcs,
#     dependencies: deps,
    install: false,
    link_with: libraries
)