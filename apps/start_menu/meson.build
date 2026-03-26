vala = meson.get_compiler('vala')
posix_dep = vala.find_library('posix')

executable(
  'start_menu',
  'src/main.vala',
  dependencies: [
    gtk_dep,
    dependency('gio-unix-2.0'),
    dependency('gtk4-layer-shell-0'),
    posix_dep,
  ],
  install: true
)