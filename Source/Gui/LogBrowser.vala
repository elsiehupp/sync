/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <cstdio>
// #include <iostream>

// #include <QDialogButtonBox>
// #include <QLayout>
// #include <QPushButton>
// #include <QLabel>
// #include <QDir>
// #include <QTextStream>
// #include <QMessageBox>
// #include <QCoreApplication>
// #include <QSettings>
// #include <QAction>
// #include <QDesktopServices>

// #include <QCheckBox>
// #include <QPlain_text_edit>
// #include <QTextStream>
// #include <GLib.File>
// #include <GLib.List>
// #include <QDateTime>
// #include <Gtk.Dialog>
// #include <QLineEdit>
// #include <QPushButton>
// #include <QLabel>

namespace Occ {

/***********************************************************
@brief The Log_browser class
@ingroup gui
***********************************************************/
class Log_browser : Gtk.Dialog {

    public Log_browser (Gtk.Widget parent = nullptr);
    ~Log_browser () override;


    protected void close_event (QCloseEvent *) override;

protected slots:
    void toggle_permanent_logging (bool enabled);
};


    Log_browser.Log_browser (Gtk.Widget parent)
        : Gtk.Dialog (parent) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        set_object_name ("Log_browser"); // for save/restore_geometry ()
        set_window_title (_("Log Output"));
        set_minimum_width (600);

        var main_layout = new QVBoxLayout;

        var label = new QLabel (
            _("The client can write debug logs to a temporary folder. "
               "These logs are very helpful for diagnosing problems.\n"
               "Since log files can get large, the client will on_start a new one for each sync "
               "run and compress older ones. It will also delete log files after a couple "
               "of hours to avoid consuming too much disk space.\n"
               "If enabled, logs will be written to %1")
            .arg (Logger.instance ().temporary_folder_log_dir_path ()));
        label.set_word_wrap (true);
        label.set_text_interaction_flags (Qt.Text_selectable_by_mouse);
        label.set_size_policy (QSize_policy.Expanding, QSize_policy.Minimum_expanding);
        main_layout.add_widget (label);

        // button to permanently save logs
        var enable_logging_button = new QCheckBox;
        enable_logging_button.on_set_text (_("Enable logging to temporary folder"));
        enable_logging_button.set_checked (ConfigFile ().automatic_log_dir ());
        connect (enable_logging_button, &QCheckBox.toggled, this, &Log_browser.toggle_permanent_logging);
        main_layout.add_widget (enable_logging_button);

        label = new QLabel (
            _("This setting persists across client restarts.\n"
               "Note that using any logging command line options will override this setting."));
        label.set_word_wrap (true);
        label.set_size_policy (QSize_policy.Expanding, QSize_policy.Minimum_expanding);
        main_layout.add_widget (label);

        var open_folder_button = new QPushButton;
        open_folder_button.on_set_text (_("Open folder"));
        connect (open_folder_button, &QPushButton.clicked, this, [] () {
            string path = Logger.instance ().temporary_folder_log_dir_path ();
            QDir ().mkpath (path);
            QDesktopServices.open_url (GLib.Uri.from_local_file (path));
        });
        main_layout.add_widget (open_folder_button);

        var btnbox = new QDialogButtonBox;
        QPushButton close_btn = btnbox.add_button (QDialogButtonBox.Close);
        connect (close_btn, &QAbstractButton.clicked, this, &Gtk.Widget.close);

        main_layout.add_stretch ();
        main_layout.add_widget (btnbox);

        set_layout (main_layout);

        set_modal (false);

        var show_log_window = new QAction (this);
        show_log_window.set_shortcut (QKeySequence ("F12"));
        connect (show_log_window, &QAction.triggered, this, &Gtk.Widget.close);
        add_action (show_log_window);

        ConfigFile cfg;
        cfg.restore_geometry (this);
    }

    Log_browser.~Log_browser () = default;

    void Log_browser.close_event (QCloseEvent *) {
        ConfigFile cfg;
        cfg.save_geometry (this);
    }

    void Log_browser.toggle_permanent_logging (bool enabled) {
        ConfigFile ().set_automatic_log_dir (enabled);

        var logger = Logger.instance ();
        if (enabled) {
            if (!logger.is_logging_to_file ()) {
                logger.setup_temporary_folder_log_dir ();
                logger.on_enter_next_log_file ();
            }
        } else {
            logger.disable_temporary_folder_log_dir ();
        }
    }

    } // namespace
    