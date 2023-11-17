srcs = files([
    'AbstractTestXmlParse.vala',
    'TestHrefUrlEncoding.vala',
    'TestParser1.vala',
    'TestParserBogusHref1.vala',
    'TestParserBogusHref2.vala',
    'TestParserBrokenXml.vala',
    'TestParserDenormalizedPathOutsideNamespace.vala',
    'TestParserDenormalizedPath.vala',
    'TestParserEmptyXmlNoDav.vala',
    'TestParserEmptyXml.vala',
    'TestParserTruncatedXml.vala',
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