int main (string[] args) {
    var env = new Flapp.Environment ();
    var plugin_dir = GLib.Path.build_filename (Config.LIBDIR, "fluorine", "apps");
    var runtime = GLib.Environment.get_user_runtime_dir ();

    Flstart.StartupEntry[] sequence = {

        new Flstart.ProcessEntry.argv ("labwc", { "labwc" }) {
            wait_mode = Flstart.WaitMode.PATH,
            wait_for = GLib.Path.build_filename (runtime, "wayland-1"),
            timeout_ms = 5000,
            restart = true,
        },

        new Flstart.PluginEntry ("libhello_world", plugin_dir),
    };

    foreach (var entry in sequence) {
        try {
            entry.launch (env);
        } catch (GLib.Error e) {
            warning ("flstart: '%s' failed: %s", entry.label, e.message);
        }
    }

    new GLib.MainLoop ().run ();
    return 0;
}
