flapp_sources = files('src/component.vala')

flapp_lib = library(
    'flapp',
    flapp_sources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
    ],
    install: true,
)

flapp_dep = declare_dependency(
    link_with: flapp_lib,
    include_directories: [
        include_directories('src'),
        include_directories('.'),
    ],
)
