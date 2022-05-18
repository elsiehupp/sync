/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <cstdio>
//  #include <iostream>
//  #include <GLib.DialogB
//  #include <GLib.Layout>
//  #include <GLib.PushBu
//  #include <GLib.Labe
//  #include <GLib.Dir>
//  #include <GLib.OutputStream>
//  #include <Gtk.MessageBox>
//  #include <GLib.CoreAppli
//  #include <GLib.Setting
//  #include <GLib.Action>
//  #include <GLib.DesktopSe
//  #include <GLib.CheckBox>
//  #include <GLib.Plain_tex
//  #include <GLib.OutputStream
//  #include <Gtk.Dialog>
//  #include <Gtk.LineEdit>
//  #include <GLib.PushButton>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The LogBrowser class
@ingroup gui
***********************************************************/
public class LogBrowser : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public LogBrowser (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);
        object_name ("LogBrowser"); // for save/restore_geometry ()
        window_title (_("Log Output"));
        minimum_width (600);

        var main_layout = new Gtk.Box (Gtk.Orientation.VERTICAL);

        var label = new Gtk.Label (
            _("The client can write debug logs to a temporary folder. "
            + "These logs are very helpful for diagnosing problems.\n"
            + "Since log files can get large, the client will on_signal_start a new one for each sync "
            + "run and compress older ones. It will also delete log files after a couple "
            + "of hours to avoid consuming too much disk space.\n"
            + "If enabled, logs will be written to %1")
            .printf (LibSync.Logger.instance.temporary_folder_log_dir_path));
        label.word_wrap (true);
        label.text_interaction_flags (GLib.Text_selectable_by_mouse);
        label.size_policy (GLib.SizePolicy.Expanding, GLib.SizePolicy.Minimum_expanding);
        main_layout.add_widget (label);

        // button to permanently save logs
        var enable_logging_button = new GLib.CheckBox ();
        enable_logging_button.on_signal_text (_("Enable logging to temporary folder"));
        enable_logging_button.checked (ConfigFile ().automatic_log_dir ());
        enable_logging_button.toggled.connect (
            this.toggle_permanent_logging
        );
        main_layout.add_widget (enable_logging_button);

        label = new Gtk.Label (
            _("This setting persists across client restarts.\n"
            + "Note that using any logging command line options will override this setting."));
        label.word_wrap (true);
        label.size_policy (GLib.SizePolicy.Expanding, GLib.SizePolicy.Minimum_expanding);
        main_layout.add_widget (label);

        var open_folder_button = new GLib.PushButton ();
        open_folder_button.on_signal_text (_("Open folder"));
        open_folder_button.clicked.connect (
            this.on_open_folder_button_clicked
        );
        main_layout.add_widget (open_folder_button);

        var btnbox = new GLib.DialogButtonBox ();
        GLib.PushButton close_button = btnbox.add_button (GLib.DialogButtonBox.Close);
        close_button.clicked.connect (
            this.close
        );

        main_layout.add_stretch ();
        main_layout.add_widget (btnbox);

        this.layout = main_layout;

        this.modal = false;

        var show_log_window_action = new GLib.Action (this);
        show_log_window_action.shortcut (GLib.KeySequence ("F12"));
        show_log_window_action.triggered.connect (
            this.close
        );
        add_action (show_log_window_action);

        ConfigFile config;
        config.restore_geometry (this);
    }


    /***********************************************************
    ***********************************************************/
    private void on_open_folder_button_clicked () {
        string path = LibSync.Logger.instance.temporary_folder_log_dir_path;
        new GLib.Dir ().mkpath (path);
        GLib.DesktopServices.open_url (GLib.Uri.from_local_file (path));
    }


    /***********************************************************
    ***********************************************************/
    protected override void close_event (GLib.CloseEvent event) {
        ConfigFile config;
        config.save_geometry (this);
    }


    /***********************************************************
    ***********************************************************/
    protected void toggle_permanent_logging (bool enabled) {
        ConfigFile ().automatic_log_dir (enabled);

        var logger = LibSync.Logger.instance;
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
