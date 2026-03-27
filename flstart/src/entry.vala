namespace Flstart {

    public abstract class StartupEntry : GLib.Object {
        public abstract string label { get; }
        public abstract void launch (Flapp.Environment env) throws GLib.Error;
    }

    public class PluginEntry : StartupEntry {
        private string plugin_name;
        private string plugin_dir;

        public override string label { get { return plugin_name; } }

        public PluginEntry (string name, string dir) {
            plugin_name = name;
            plugin_dir = dir;
        }

        public override void launch (Flapp.Environment env) throws GLib.Error {
            var path = GLib.Path.build_filename (plugin_dir, plugin_name + ".so");

            var mod = GLib.Module.open (path, GLib.ModuleFlags.LAZY);
            if (mod == null)
                throw new GLib.IOError.NOT_FOUND (
                    "could not load '%s': %s", path, GLib.Module.error ()
                );

            void* sym;
            if (!mod.symbol ("fluorine_component_create", out sym))
                throw new GLib.IOError.FAILED (
                    "'%s' has no fluorine_component_create", plugin_name
                );

            var component = ((Flapp.ComponentFactory) sym) ();
            env.register (component);
            component.set_data<GLib.Module> ("_module", (owned) mod);
            component.start (env);
            message ("flstart: started plugin '%s'", plugin_name);
        }
    }

    public enum WaitMode {
        NONE,
        EXIT,
        PATH,
        DELAY,
        NEW_WAYLAND_SOCKET,
    }

    public class ProcessEntry : StartupEntry {
        private string _label;
        private string[] _argv;

        public WaitMode wait_mode { get; set; default = WaitMode.NONE; }
        public string wait_for { get; set; default = ""; }
        public uint timeout_ms { get; set; default = 10000; }
        public bool restart { get; set; default = false; }
        public string[] env_overrides { get; set; default = {}; }
        public string[] unset_env { get; set; default = {}; }

        public override string label { get { return _label; } }

        public ProcessEntry.cmd (string cmd) {
            _label = cmd.split (" ")[0];
            _argv = cmd.split (" ");
        }

        public ProcessEntry.argv (string label, string[] args) {
            _label = label;
            _argv = args;
        }

        public override void launch (Flapp.Environment env) throws GLib.Error {
            message ("flstart: launching '%s'", _label);

            var launcher = new GLib.SubprocessLauncher (GLib.SubprocessFlags.NONE);
            foreach (var kv in env_overrides) {
                var parts = kv.split ("=", 2);
                launcher.setenv (parts[0], parts[1], true);
            }
            foreach (var key in unset_env)
                launcher.unsetenv (key);

            var proc = launcher.spawnv (_argv);

            if (restart) {
                proc.wait_async.begin (null, (obj, res) => {
                    try { proc.wait_async.end (res); } catch {}
                    message ("flstart: '%s' exited, restarting", _label);
                    try { launch (env); } catch (GLib.Error e) {
                        warning ("flstart: restart of '%s' failed: %s", _label, e.message);
                    }
                });
            }

            switch (wait_mode) {
                case WaitMode.EXIT:
                    proc.wait ();
                    break;
                case WaitMode.PATH:
                    wait_for_path (wait_for);
                    break;
                case WaitMode.DELAY:
                    GLib.Thread.usleep (timeout_ms * 1000);
                    break;
                case WaitMode.NEW_WAYLAND_SOCKET:
                    wait_for_new_wayland_socket ();
                    break;
                case WaitMode.NONE:
                default:
                    break;
            }
        }

        private void wait_for_path (string path) {
            message ("flstart: waiting for '%s'", path);
            var deadline = GLib.get_monotonic_time () + (timeout_ms * 1000);
            while (!GLib.FileUtils.test (path, GLib.FileTest.EXISTS)) {
                if (GLib.get_monotonic_time () > deadline) {
                    warning ("flstart: timed out waiting for '%s'", path);
                    return;
                }
                GLib.Thread.usleep (50000);
            }
            message ("flstart: '%s' appeared", path);
        }

        private void wait_for_new_wayland_socket () {
            var runtime = GLib.Environment.get_user_runtime_dir ();
            message ("flstart: waiting for new wayland socket in '%s'", runtime);

            // snapshot existing sockets
            var before = new GLib.GenericSet<string> (str_hash, str_equal);
            try {
                var dir = GLib.Dir.open (runtime);
                string? name;
                while ((name = dir.read_name ()) != null) {
                    if (name.has_prefix ("wayland-") && !name.has_suffix (".lock"))
                        before.add (name);
                }
            } catch {}

            var deadline = GLib.get_monotonic_time () + (timeout_ms * 1000);
            while (true) {
                if (GLib.get_monotonic_time () > deadline) {
                    warning ("flstart: timed out waiting for new wayland socket");
                    return;
                }
                GLib.Thread.usleep (50000);

                try {
                    var dir = GLib.Dir.open (runtime);
                    string? name;
                    while ((name = dir.read_name ()) != null) {
                        if (name.has_prefix ("wayland-") && !name.has_suffix (".lock") && !before.contains (name)) {
                            var socket = name;
                            message ("flstart: new wayland socket '%s' appeared", socket);
                            GLib.Environment.set_variable ("WAYLAND_DISPLAY", socket, true);
                            return;
                        }
                    }
                } catch {}
            }
        }
    }

}