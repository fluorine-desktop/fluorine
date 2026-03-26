using Gtk;

int main (string[] args) {
    var app = new Gtk.Application ("com.w4194304.hello_world", GLib.ApplicationFlags.DEFAULT_FLAGS);

    app.activate.connect (() => {
        var window = new ApplicationWindow (app);
        window.title = "Hello, World!";
        window.set_default_size (300, 200);

        var label = new Label ("Hello, World!");
        window.set_child (label);
        window.present ();
    });

    return app.run (args);
}
