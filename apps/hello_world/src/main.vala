using Gtk;

public class HelloWorld : Gtk.Application, Flapp.Component {
    public string component_name { get { return "hello-world"; } }

    public HelloWorld () {
        Object (application_id: "sh.fluorine.HelloWorld",
                flags: ApplicationFlags.DEFAULT_FLAGS);
    }

    public void start (Flapp.Environment env) {
        try { this.register (null); } catch (GLib.Error e) {
            warning ("hello-world: register failed: %s", e.message);
        }
        this.activate ();
    }

    public void stop () { this.quit (); }

    protected override void activate () {
        var win = new Gtk.ApplicationWindow (this);
        win.title = "Hello, World!";
        win.set_default_size (300, 200);
        win.set_child (new Gtk.Label ("Hello, World!"));
        win.present ();
    }
}

[CCode (cname = "fluorine_component_create")]
public Flapp.Component fluorine_component_create () {
    return new HelloWorld ();
}
