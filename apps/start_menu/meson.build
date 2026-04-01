vala = meson.get_compiler('vala')
posix_dep = vala.find_library('posix')

layer_shell_dep = dependency('gtk4-layer-shell-0')
layer_shell_vapidir = layer_shell_dep.get_variable(pkgconfig: 'vapidir', default_value: '')

start_menu_deps = [
    gtk_dep,
    dependency('gio-unix-2.0'),
    layer_shell_dep,
    posix_dep,
    flapp_dep,
]

start_menu_vala_args = layer_shell_vapidir != '' ? ['--vapidir=' + layer_shell_vapidir] : []

executable('start_menu',
    'src/main.vala',
    dependencies: start_menu_deps,
    vala_args: start_menu_vala_args,
    install: true,
    install_rpath: get_option('prefix') / get_option('libdir'),
)

shared_library('flaunch',
    'src/main.vala',
    dependencies: start_menu_deps,
    vala_args: start_menu_vala_args,
    name_prefix: '',
    install: true,
    install_dir: get_option('libdir') / 'fluorine' / 'apps',
)
