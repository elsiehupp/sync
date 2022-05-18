srcs = files([
    'QTokenizer.vala',
    'QStringTokenizer.vala',
    'Test/TestQTokenizer.vala',
])

libraries = [
    subproject('Gpseq').get_variable ('gpseq_lib')
]

library(
    'QTokenizer',
    srcs,
#     dependencies: deps,
    install: false,
    link_with: libraries
)