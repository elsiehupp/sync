/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <cstdio>
//  #include <iostream>
//  #include <QDialogB
//  #include <QLayout>
//  #include <QPushBu
//  #include <QLabe
//  #include <QDir>
//  #include <QTextStream>
//  #include <QMessageBox>
//  #include <QCoreAppli
//  #include <QSetting
//  #include <QAction>
//  #include <QDesktopSe
//  #include <QCheckBox>
//  #include <QPlain_tex
//  #include <QTextStream
//  #include <Gtk.Dialog>
//  #include <QLineEdit>
//  #include <QPushButton>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The LogBrowser class
@ingroup gui
***********************************************************/
public class LogBrowser : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public LogBrowser (Gtk.Widget parent = null) {
        base (parent);
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        object_name ("LogBrowser"); // for save/restore_geometry ()
        window_title (_("Log Output"));
        minimum_width (600);

        var main_layout = new QVBoxLayout ();

        var label = new Gtk.Label (
            _("The client can write debug logs to a temporary folder. "
            + "These logs are very helpful for diagnosing problems.\n"
            + "Since log files can get large, the client will on_signal_start a new one for each sync "
            + "run and compress older ones. It will also delete log files after a couple "
            + "of hours to avoid consuming too much disk space.\n"
            + "If enabled, logs will be written to %1")
            .arg (Logger.instance ().temporary_folder_log_dir_path ()));
        label.word_wrap (true);
        label.text_interaction_flags (Qt.Text_selectable_by_mouse);
        label.size_policy (QSizePolicy.Expanding, QSizePolicy.Minimum_expanding);
        main_layout.add_widget (label);

        // button to permanently save logs
        var enable_logging_button = new QCheckBox ();
        enable_logging_button.on_signal_text (_("Enable logging to temporary folder"));
        enable_logging_button.checked (ConfigFile ().automatic_log_dir ());
        connect (enable_logging_button, QCheckBox.toggled, this, LogBrowser.toggle_permanent_logging);
        main_layout.add_widget (enable_logging_button);

        label = new Gtk.Label (
            _("This setting persists across client restarts.\n"
            + "Note that using any logging command line options will override this setting."));
        label.word_wrap (true);
        label.size_policy (QSizePolicy.Expanding, QSizePolicy.Minimum_expanding);
        main_layout.add_widget (label);

        var open_folder_button = new QPushButton ();
        open_folder_button.on_signal_text (_("Open folder"));
        connect (
            open_folder_button,
            QPushButton.clicked,
            this,
            this.on_open_folder_button_clicked
        );
        main_layout.add_widget (open_folder_button);

        var btnbox = new QDialogButtonBox ();
        QPushButton close_btn = btnbox.add_button (QDialogButtonBox.Close);
        connect (
            close_btn,
            QAbstractButton.clicked,
            this,
            Gtk.Widget.close
        );

        main_layout.add_stretch ();
        main_layout.add_widget (btnbox);

        layout (main_layout);

        modal (false);

        var show_log_window = new QAction (this);
        show_log_window.shortcut (QKeySequence ("F12"));
        connect (show_log_window, QAction.triggered, this, Gtk.Widget.close);
        add_action (show_log_window);

        ConfigFile config;
        config.restore_geometry (this);
    }


    /***********************************************************
    ***********************************************************/
    private void on_open_folder_button_clicked () {
        string path = Logger.instance ().temporary_folder_log_dir_path ();
        QDir ().mkpath (path);
        QDesktopServices.open_url (GLib.Uri.from_local_file (path));
    }


    /***********************************************************
    ***********************************************************/
    protected override void close_event (QCloseEvent event) {
        ConfigFile config;
        config.save_geometry (this);
    }


    /***********************************************************
    ***********************************************************/
    protected void toggle_permanent_logging (bool enabled) {
        ConfigFile ().automatic_log_dir (enabled);

        var logger = Logger.instance ();
        if (enabled) {
            if (!logger.is_logging_to_file ()) {
                logger.setup_temporary_folder_log_dir ();
                logger.on_signal_enter_next_log_file ();
            }
        } else {
            logger.disable_temporary_folder_log_dir ();
        }
    }

} // class LogBrowser

} // namespace Ui
} // namespace Occ
