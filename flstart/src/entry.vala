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
    }

    public class ProcessEntry : StartupEntry {
        private string _label;
        private string[] _argv;

        public WaitMode wait_mode { get; set; default = WaitMode.NONE; }
        public string wait_for { get; set; default = ""; }
        public uint timeout_ms { get; set; default = 10000; }
        public bool restart { get; set; default = false; }

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
            var proc = new GLib.Subprocess.newv (_argv, GLib.SubprocessFlags.NONE);

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
    }

}
