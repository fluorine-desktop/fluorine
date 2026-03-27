conf = configuration_data()
conf.set('LIBDIR', get_option('prefix') / get_option('libdir'))

configure_file(
    input:         'src/config.vala.in',
    output:        'config.vala',
    configuration: conf,
)

executable(
    'flstart',
    files('src/main.vala', 'src/entry.vala') +
        [meson.current_build_dir() / 'config.vala'],
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gio-2.0'),
        dependency('gmodule-2.0'),
        flapp_dep,
    ],
    install: true,
    install_rpath: get_option('prefix') / get_option('libdir'),
)
