
subdir('Kirigami')
subdir('KMessageWidget')
subdir('QProgressIndicator')
subdir('QTokenizer')
subdir('QtSingleApplication')

3rd_party_lib = library(
    meson.project_name(),
    srcs,
    dependencies: deps,
    install: false
)

3rd_party_dep = declare_dependency(
    link_with: 3rd_party_lib, 
    include_directories: include_directories('.')
)
