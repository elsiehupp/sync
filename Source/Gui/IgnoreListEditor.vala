/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QDir>
// #include <QList_widget>
// #include <QListWidgetTtem>
// #include <QMessageBox>
// #include <QInputDialog>

// #include <Gtk.Dialog>


namespace Occ {

namespace Ui {
    class Ignore_list_editor;
}

/***********************************************************
@brief The Ignore_list_editor class
@ingroup gui
***********************************************************/
class Ignore_list_editor : Gtk.Dialog {

    public Ignore_list_editor (Gtk.Widget *parent = nullptr);
    ~Ignore_list_editor () override;

    public bool ignore_hidden_files ();


    private void on_restore_defaults (QAbstractButton *button);


    private void setup_table_read_only_items ();
    private string read_only_tooltip;
    private Ui.Ignore_list_editor *ui;
};


    Ignore_list_editor.Ignore_list_editor (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.Ignore_list_editor) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        ui.setup_ui (this);

        ConfigFile cfg_file;
        //FIXME This is not true. The entries are hardcoded below in setup_table_read_only_items
        read_only_tooltip = tr ("This entry is provided by the system at \"%1\" "
                             "and cannot be modified in this view.")
                              .arg (QDir.to_native_separators (cfg_file.exclude_file (ConfigFile.SystemScope)));

        setup_table_read_only_items ();
        const auto user_config = cfg_file.exclude_file (ConfigFile.Scope.UserScope);
        ui.ignore_table_widget.read_ignore_file (user_config);

        connect (this, &Gtk.Dialog.accepted, [=] () {
            ui.ignore_table_widget.on_write_ignore_file (user_config);
            /* handle the hidden file checkbox */

            /* the ignore_hidden_files flag is a folder specific setting, but for now, it is
           handled globally. Save it to every folder that is defined.
           TODO this can now be fixed, simply attach this Ignore_list_editor to top-level account
           settings
            */
            FolderMan.instance ().set_ignore_hidden_files (ignore_hidden_files ());
        });
        connect (ui.button_box, &QDialogButtonBox.clicked,
                this, &Ignore_list_editor.on_restore_defaults);

        ui.sync_hidden_files_check_box.set_checked (!FolderMan.instance ().ignore_hidden_files ());
    }

    Ignore_list_editor.~Ignore_list_editor () {
        delete ui;
    }

    void Ignore_list_editor.setup_table_read_only_items () {
        ui.ignore_table_widget.add_pattern (".csync_journal.db*", /*deletable=*/false, /*readonly=*/true);
        ui.ignore_table_widget.add_pattern ("._sync_*.db*", /*deletable=*/false, /*readonly=*/true);
        ui.ignore_table_widget.add_pattern (".sync_*.db*", /*deletable=*/false, /*readonly=*/true);
    }

    bool Ignore_list_editor.ignore_hidden_files () {
        return !ui.sync_hidden_files_check_box.is_checked ();
    }

    void Ignore_list_editor.on_restore_defaults (QAbstractButton *button) {
        if (ui.button_box.button_role (button) != QDialogButtonBox.Reset_role)
            return;

        ui.ignore_table_widget.on_remove_all_items ();

        ConfigFile cfg_file;
        setup_table_read_only_items ();
        ui.ignore_table_widget.read_ignore_file (cfg_file.exclude_file (ConfigFile.SystemScope), false);
    }

    } // namespace Occ
    