using Gtk;
using GLib;

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

    protected override void activate () {
        var win = new Gtk.ApplicationWindow (this);
        win.title = "Start Menu";
        win.set_default_size (600, 400);

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
                img.pixel_size = 32;
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

            int score_a = score_app (app_a, entry.text);
            int score_b = score_app (app_b, entry.text);

            return score_b - score_a;
        });


        entry.search_changed.connect (() => {
            list.invalidate_filter ();
            list.invalidate_sort ();
        });


        list.row_activated.connect ((row) => {
            var app = (AppInfo) row.get_data<AppInfo> ("app-info");
            try {
                app.launch (null, null);
                win.close ();
            } catch (Error e) {
                stderr.printf ("Failed to launch: %s\n", e.message);
            }
        });

        win.present ();
        entry.grab_focus ();

        entry.activate.connect (() => {
            var first = list.get_row_at_index (0);
            if (first != null && first.get_child_visible ())
                list.row_activated (first);
        });
    }
}

public static int main (string[] args) {
    return new StartMenu ().run (args);
}
