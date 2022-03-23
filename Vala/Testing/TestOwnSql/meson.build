srcs = files([
    'AbstractTestOwnSql.vala',
    'TestCreate.vala',
    'TestDestructor.vala',
    'TestInsert1.vala',
    'TestInsert2.vala',
    'TestPragma.vala',
    'TestSelect1.vala',
    'TestSelect2.vala',
    'TestSelect3.vala',
    'TestUnicodeExec.vala',
    'TestUnicodeRead.vala',
])

# Dependences
deps = [
    # dependency('gio-2.0'),
    # dependency('gtk+-3.0'),
    # dependency('granite'),
    # dependency('gee-0.8'),
    # dependency('json-glib-1.0'),
    # dependency('libsoup-2.4'),
    # libsqlite3-dev
    dependency('sqlite3'),
]

executable(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)