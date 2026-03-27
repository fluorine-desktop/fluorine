using Gtk;
using GLib;
using GtkLayerShell;

public class StartMenu : Gtk.Application {
    public StartMenu () {
        Object (application_id: "sh.fluorine.StartMenu",
               flags: ApplicationFlags.DEFAULT_FLAGS);
    }

    int score_app (AppInfo app, string query) {
        string q = query.down ().strip ();

        var name = app.get_display_name ().down ();
        var exec = app.get_executable () != null ? app.get_executable ().down () : "";

        if (q == "") return 0;

        var terms = q.split (" ");
        int score = 0;

        foreach (var term in terms) {
            if (term == "") continue;

            bool matched = false;

            if (name.has_prefix (term)) {
                score += 100;
                matched = true;
            }

            foreach (var word in name.split (" ")) {
                if (word.has_prefix (term)) {
                    score += 75;
                    matched = true;
                    break;
                }
            }

            if (!matched && name.contains (term)) {
                score += 50;
                matched = true;
            }

            if (!matched && exec.contains (term)) {
                score += 30;
                matched = true;
            }

            if (!matched)
                return 0;
        }

        return score;
    }

    Gtk.ListBoxRow? first_visible_row (Gtk.ListBox list) {
        int i = 0;
        while (true) {
            var row = list.get_row_at_index (i++);
            if (row == null) return null;
            if (row.get_mapped ()) return row;
        }
    }

    Gtk.ListBoxRow? navigate (Gtk.ListBox list, Gtk.ListBoxRow? current, int dir) {
        if (current == null)
            return dir > 0 ? first_visible_row (list) : null;

        int i = current.get_index () + dir;
        while (i >= 0) {
            var row = list.get_row_at_index (i);
            if (row == null) break;
            if (row.get_mapped ()) return row;
            i += dir;
        }
        return null;
    }

    void launch_app (AppInfo app, Gtk.ApplicationWindow win) {
        string[]? argv = null;

        var desktop_app = app as DesktopAppInfo;
        if (desktop_app != null) {
            string? cmdline = desktop_app.get_commandline ();
            if (cmdline != null) {
                try {
                    var cleaned = new Regex ("%[uUfFdDnNickvmh]").replace (cmdline, -1, 0, "").strip ();
                    Shell.parse_argv (cleaned, out argv);
                } catch (Error e) {
                    stderr.printf ("Failed to parse command for %s: %s\n", app.get_display_name (), e.message);
                    return;
                }
            }
        }

        if (argv == null) {
            string? exe = app.get_executable ();
            if (exe == null) {
                stderr.printf ("No executable found for %s\n", app.get_display_name ());
                return;
            }
            argv = { exe };
        }

        try {
            Process.spawn_async (
                null,
                argv,
                null,
                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                () => { Posix.setsid (); },
                null
            );
            win.close ();
        } catch (SpawnError e) {
            stderr.printf ("Failed to launch %s: %s\n", app.get_display_name (), e.message);
        }
    }

    protected override void activate () {
        var win = new Gtk.ApplicationWindow (this);
        win.title = "Start Menu";
        win.set_default_size (280, 550);
        win.decorated = false;

        GtkLayerShell.init_for_window (win);
        GtkLayerShell.set_layer (win, GtkLayerShell.Layer.TOP);
        GtkLayerShell.set_anchor (win, GtkLayerShell.Edge.BOTTOM, true);
        GtkLayerShell.set_anchor (win, GtkLayerShell.Edge.LEFT, true);
        GtkLayerShell.set_margin (win, GtkLayerShell.Edge.BOTTOM, 0);
        GtkLayerShell.set_margin (win, GtkLayerShell.Edge.LEFT, 0);
        GtkLayerShell.set_keyboard_mode (win, GtkLayerShell.KeyboardMode.EXCLUSIVE);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        win.set_child (box);

        var entry = new Gtk.SearchEntry ();
        entry.placeholder_text = "Search apps…";
        entry.margin_top = 8;
        entry.margin_bottom = 8;
        entry.margin_start = 8;
        entry.margin_end = 8;
        box.append (entry);

        var scroll = new Gtk.ScrolledWindow ();
        scroll.vexpand = true;
        box.append (scroll);

        var list = new Gtk.ListBox ();
        list.selection_mode = Gtk.SelectionMode.SINGLE;
        scroll.set_child (list);

        var all_apps = AppInfo.get_all ();

        foreach (var app in all_apps) {
            if (!app.should_show ()) continue;

            var row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            row_box.margin_top = 4;
            row_box.margin_bottom = 4;
            row_box.margin_start = 8;
            row_box.margin_end = 8;

            var icon = app.get_icon ();
            if (icon != null) {
                var img = new Gtk.Image.from_gicon (icon);
                img.pixel_size = 24;
                row_box.append (img);
            }

            var label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var name_label = new Gtk.Label (app.get_display_name ());
            name_label.halign = Gtk.Align.START;
            label_box.append (name_label);

            var desc = app.get_description ();
            if (desc != null) {
                var desc_label = new Gtk.Label (desc);
                desc_label.halign = Gtk.Align.START;
                desc_label.add_css_class ("dim-label");
                desc_label.ellipsize = Pango.EllipsizeMode.END;
                label_box.append (desc_label);
            }

            row_box.append (label_box);

            var list_row = new Gtk.ListBoxRow ();
            list_row.set_child (row_box);
            list_row.set_data ("app-info", app);

            list.append (list_row);
        }

        list.set_filter_func ((row) => {
            var query = entry.text;
            if (query.strip () == "") return true;
            var app = (AppInfo) row.get_data<AppInfo> ("app-info");
            return score_app (app, query) > 0;
        });

        list.set_sort_func ((a, b) => {
            var app_a = (AppInfo) a.get_data<AppInfo> ("app-info");
            var app_b = (AppInfo) b.get_data<AppInfo> ("app-info");
            return score_app (app_b, entry.text) - score_app (app_a, entry.text);
        });

        entry.search_changed.connect (() => {
            list.invalidate_filter ();
            list.invalidate_sort ();
            list.select_row (null);
        });

        list.row_activated.connect ((row) => {
            launch_app ((AppInfo) row.get_data<AppInfo> ("app-info"), win);
        });

        entry.activate.connect (() => {
            var row = list.get_selected_row () ?? first_visible_row (list);
            if (row != null)
                launch_app ((AppInfo) row.get_data<AppInfo> ("app-info"), win);
        });

        var key_ctrl = new Gtk.EventControllerKey ();
        key_ctrl.key_pressed.connect ((keyval, keycode, state) => {
            switch (keyval) {
                case Gdk.Key.Escape:
                    win.close ();
                    return true;
                case Gdk.Key.Down:
                case Gdk.Key.Up:
                    int dir = (keyval == Gdk.Key.Down) ? 1 : -1;
                    var next = navigate (list, list.get_selected_row (), dir);
                    if (next != null) {
                        list.select_row (next);
                        next.grab_focus ();
                        entry.grab_focus ();
                    }
                    return true;
                default:
                    return false;
            }
        });
        entry.add_controller (key_ctrl);

        win.present ();
        entry.grab_focus ();
    }
}

public static int main (string[] args) {
    return new StartMenu ().run (args);
}
