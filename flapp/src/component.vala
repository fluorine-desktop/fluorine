namespace Flapp {

    public interface Component : GLib.Object {
        public abstract string component_name { get; }
        public abstract void start (Environment env);
        public abstract void stop ();
    }

    public class Environment : GLib.Object {
        private HashTable<string, Component> registry;

        construct {
            registry = new HashTable<string, Component> (str_hash, str_equal);
        }

        public void register (Component c) {
            registry.insert (c.component_name, c);
            message ("flapp: registered '%s'", c.component_name);
        }

        public Component? require (string name) {
            var c = registry.lookup (name);
            if (c == null)
                warning ("flapp: component '%s' not found", name);
            return c;
        }

        public bool has (string name) {
            return registry.contains (name);
        }
    }

    [CCode (has_target = false)]
    public delegate Component ComponentFactory ();

}
