//  #pragma once

// #include <Gtk.Widget>
// #include <QInputDialog>
// #include <QLineEdit>
// #include <QMessageBox>


namespace Occ {

namespace Ui {
    class IgnoreListTableWidget;
}

class IgnoreListTableWidget : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public IgnoreListTableWidget (Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int add_pattern (string patte

    /***********************************************************
    ***********************************************************/
    public void on_remove_all_items ();


    public void on_write_ignore_file (string  file);


    /***********************************************************
    ***********************************************************/
    private void on_item_selection_changed ();
    private void on_remove_current_item ();
    private void on_add_pattern ();


    /***********************************************************
    ***********************************************************/
    private void setup_table_read_only_items ();
    private string read_only_tooltip;
    private Ui.IgnoreListTableWidget ui;
}


    /***********************************************************
    ***********************************************************/
    static constexpr int pattern_col = 0;
    static constexpr int deletable_col = 1;
    static constexpr int read_only_rows = 3;

    IgnoreListTableWidget.IgnoreListTableWidget (Gtk.Widget parent)
        : Gtk.Widget (parent)
        , ui (new Ui.IgnoreListTableWidget) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        ui.setup_ui (this);

        ui.description_label.on_set_text (_("Files or folders matching a pattern will not be synchronized.\n\n"
                                         "Items where deletion is allowed will be deleted if they prevent a "
                                         "directory from being removed. "
                                         "This is useful for meta data."));

        ui.remove_push_button.set_enabled (false);
        connect (ui.table_widget,         &QTable_widget.item_selection_changed,
                this, &IgnoreListTableWidget.on_item_selection_changed);
        connect (ui.remove_push_button,    &QAbstractButton.clicked,
                this, &IgnoreListTableWidget.on_remove_current_item);
        connect (ui.add_push_button,       &QAbstractButton.clicked,
                this, &IgnoreListTableWidget.on_add_pattern);
        connect (ui.remove_all_push_button, &QAbstractButton.clicked,
                this, &IgnoreListTableWidget.on_remove_all_items);

        ui.table_widget.resize_columns_to_contents ();
        ui.table_widget.horizontal_header ().set_section_resize_mode (pattern_col, QHeaderView.Stretch);
        ui.table_widget.vertical_header ().set_visible (false);
    }

    IgnoreListTableWidget.~IgnoreListTableWidget () {
        delete ui;
    }

    void IgnoreListTableWidget.on_item_selection_changed () {
        QTable_widget_item item = ui.table_widget.current_item ();
        if (!item) {
            ui.remove_push_button.set_enabled (false);
            return;
        }

        bool enable = item.flags () & Qt.ItemIsEnabled;
        ui.remove_push_button.set_enabled (enable);
    }

    void IgnoreListTableWidget.on_remove_current_item () {
        ui.table_widget.remove_row (ui.table_widget.current_row ());
        if (ui.table_widget.row_count () == read_only_rows)
            ui.remove_all_push_button.set_enabled (false);
    }

    void IgnoreListTableWidget.on_remove_all_items () {
        ui.table_widget.set_row_count (0);
    }

    void IgnoreListTableWidget.on_write_ignore_file (string  file) {
        GLib.File ignores (file);
        if (ignores.open (QIODevice.WriteOnly)) {
            // rewrites the whole file since now the user can also remove system patterns
            GLib.File.resize (file, 0);
            for (int row = 0; row < ui.table_widget.row_count (); ++row) {
                QTable_widget_item pattern_item = ui.table_widget.item (row, pattern_col);
                QTable_widget_item deletable_item = ui.table_widget.item (row, deletable_col);
                if (pattern_item.flags () & Qt.ItemIsEnabled) {
                    GLib.ByteArray prepend;
                    if (deletable_item.check_state () == Qt.Checked) {
                        prepend = "]";
                    } else if (pattern_item.text ().starts_with ('#')) {
                        prepend = "\\";
                    }
                    ignores.write (prepend + pattern_item.text ().to_utf8 () + '\n');
                }
            }
        } else {
            QMessageBox.warning (this, _("Could not open file"),
                _("Cannot write changes to \"%1\".").arg (file));
        }
        ignores.close (); //close the file before reloading stuff.

        FolderMan folder_man = FolderMan.instance ();

        // We need to force a remote discovery after a change of the ignore list.
        // Otherwise we would not download the files/directories that are no longer
        // ignored (because the remote etag did not change)   (issue #3172)
        foreach (Folder folder, folder_man.map ()) {
            folder.journal_database ().force_remote_discovery_next_sync ();
            folder_man.schedule_folder (folder);
        }
    }

    void IgnoreListTableWidget.on_add_pattern () {
        bool ok_clicked = false;
        string pattern = QInputDialog.get_text (this, _("Add Ignore Pattern"),
            _("Add a new ignore pattern:"),
            QLineEdit.Normal, "", ok_clicked);

        if (!ok_clicked || pattern.is_empty ())
            return;

        add_pattern (pattern, false, false);
        ui.table_widget.scroll_to_bottom ();
    }

    void IgnoreListTableWidget.read_ignore_file (string file, bool read_only) {
        GLib.File ignores (file);
        if (ignores.open (QIODevice.ReadOnly)) {
            while (!ignores.at_end ()) {
                string line = string.from_utf8 (ignores.read_line ());
                line.chop (1);
                if (!line.is_empty () && !line.starts_with ("#")) {
                    bool deletable = false;
                    if (line.starts_with (']')) {
                        deletable = true;
                        line = line.mid (1);
                    }
                    add_pattern (line, deletable, read_only);
                }
            }
        }
    }

    int IgnoreListTableWidget.add_pattern (string pattern, bool deletable, bool read_only) {
        int new_row = ui.table_widget.row_count ();
        ui.table_widget.set_row_count (new_row + 1);

        var pattern_item = new QTable_widget_item;
        pattern_item.on_set_text (pattern);
        ui.table_widget.set_item (new_row, pattern_col, pattern_item);

        var deletable_item = new QTable_widget_item;
        deletable_item.set_flags (Qt.Item_is_user_checkable | Qt.ItemIsEnabled);
        deletable_item.set_check_state (deletable ? Qt.Checked : Qt.Unchecked);
        ui.table_widget.set_item (new_row, deletable_col, deletable_item);

        if (read_only) {
            pattern_item.set_flags (pattern_item.flags () ^ Qt.ItemIsEnabled);
            pattern_item.set_tool_tip (read_only_tooltip);
            deletable_item.set_flags (deletable_item.flags () ^ Qt.ItemIsEnabled);
        }

        ui.remove_all_push_button.set_enabled (true);

        return new_row;
    }

    } // namespace Occ
    