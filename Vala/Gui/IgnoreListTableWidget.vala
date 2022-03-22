//  #pragma once

//  #include <Gtk.Widget>
//  #include <QInputDialog>
//  #include <QLineEdit>
//  #include <Gtk.MessageBox>

namespace Occ {
namespace Ui {

public class IgnoreListTableWidget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    const int pattern_col = 0;
    const int deletable_col = 1;
    const int read_only_rows = 3;

    private string read_only_tooltip;
    private IgnoreListTableWidget instance;

    /***********************************************************
    ***********************************************************/
    public IgnoreListTableWidget (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new IgnoreListTableWidget ();
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        instance.up_ui (this);

        instance.description_label.on_signal_text (
            _("Files or folders matching a pattern will not be synchronized.\n\n"
            + "Items where deletion is allowed will be deleted if they prevent a "
            + "directory from being removed. "
            + "This is useful for metadata.")
        );

        instance.remove_push_button.enabled (false);
        instance.table_widget.item_selection_changed.connect (
            this.on_signal_item_selection_changed
        );
        instance.remove_push_button.clicked.connect (
            this.on_signal_remove_current_item
        );
        instance.add_push_button.clicked.connect (
            this.on_signal_add_pattern
        );
        instance.remove_all_push_button.clicked.connect (
            this.on_signal_remove_all_items
        );

        instance.table_widget.resize_columns_to_contents ();
        instance.table_widget.horizontal_header ().section_resize_mode (pattern_col, QHeaderView.Stretch);
        instance.table_widget.vertical_header ().visible (false);
    }


    ~IgnoreListTableWidget () {
        //  delete instance;
    }

    /***********************************************************
    ***********************************************************/
    public void read_ignore_file (string file, bool read_only) {
        GLib.File ignores = new GLib.File (file);
        if (ignores.open (QIODevice.ReadOnly)) {
            while (!ignores.at_end ()) {
                string line = string.from_utf8 (ignores.read_line ());
                line.chop (1);
                if (!line == "" && !line.has_prefix ("#")) {
                    bool deletable = false;
                    if (line.has_prefix (']')) {
                        deletable = true;
                        line = line.mid (1);
                    }
                    add_pattern (line, deletable, read_only);
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public int add_pattern (string pattern, bool deletable, bool read_only) {
        int new_row = instance.table_widget.row_count ();
        instance.table_widget.row_count (new_row + 1);

        var pattern_item = new QTableWidgetItem ();
        pattern_item.on_signal_text (pattern);
        instance.table_widget.item (new_row, pattern_col, pattern_item);

        var deletable_item = new QTableWidgetItem ();
        deletable_item.flags (Qt.ItemIsUserCheckable | Qt.ItemIsEnabled);
        deletable_item.check_state (deletable ? Qt.Checked : Qt.Unchecked);
        instance.table_widget.item (new_row, deletable_col, deletable_item);

        if (read_only) {
            pattern_item.flags (pattern_item.flags () ^ Qt.ItemIsEnabled);
            pattern_item.tool_tip (read_only_tooltip);
            deletable_item.flags (deletable_item.flags () ^ Qt.ItemIsEnabled);
        }

        instance.remove_all_push_button.enabled (true);

        return new_row;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remove_all_items () {
        instance.table_widget.row_count (0);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_write_ignore_file (string file) {
        GLib.File ignores = new GLib.File (file);
        if (ignores.open (QIODevice.WriteOnly)) {
            // rewrites the whole file since now the user can also remove system patterns
            GLib.File.resize (file, 0);
            for (int row = 0; row < instance.table_widget.row_count (); ++row) {
                QTableWidgetItem pattern_item = instance.table_widget.item (row, pattern_col);
                QTableWidgetItem deletable_item = instance.table_widget.item (row, deletable_col);
                if (pattern_item.flags () & Qt.ItemIsEnabled) {
                    string prepend;
                    if (deletable_item.check_state () == Qt.Checked) {
                        prepend = "]";
                    } else if (pattern_item.text ().has_prefix ('#')) {
                        prepend = "\\";
                    }
                    ignores.write (prepend + pattern_item.text ().to_utf8 () + '\n');
                }
            }
        } else {
            Gtk.MessageBox.warning (this, _("Could not open file"),
                _("Cannot write changes to \"%1\".").printf (file));
        }
        ignores.close (); //close the file before reloading stuff.

        FolderManager folder_man = FolderManager.instance;

        // We need to force a remote discovery after a change of the ignore list.
        // Otherwise we would not download the files/directories that are no longer
        // ignored (because the remote etag did not change)   (issue #3172)
        foreach (FolderConnection folder_connection in folder_man.map ()) {
            folder_connection.journal_database ().force_remote_discovery_next_sync ();
            folder_man.schedule_folder (folder_connection);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_item_selection_changed () {
        QTableWidgetItem item = instance.table_widget.current_item ();
        if (!item) {
            instance.remove_push_button.enabled (false);
            return;
        }

        bool enable = item.flags () & Qt.ItemIsEnabled;
        instance.remove_push_button.enabled (enable);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remove_current_item () {
        instance.table_widget.remove_row (instance.table_widget.current_row ());
        if (instance.table_widget.row_count () == read_only_rows)
            instance.remove_all_push_button.enabled (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_add_pattern () {
        bool ok_clicked = false;
        string pattern = QInputDialog.text (this, _("Add Ignore Pattern"),
            _("Add a new ignore pattern:"),
            QLineEdit.Normal, "", ok_clicked);

        if (!ok_clicked || pattern == "")
            return;

        add_pattern (pattern, false, false);
        instance.table_widget.scroll_to_bottom ();
    }


    /***********************************************************
    ***********************************************************/
    private void setup_table_read_only_items ();

} // class IgnoreListTableWidget

} // namespace Ui
} // namespace Occ
