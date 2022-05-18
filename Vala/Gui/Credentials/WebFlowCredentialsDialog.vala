
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

public class WebFlowCredentialsDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private bool use_flow2;

    Flow2AuthWidget flow_2_auth_widget;

    /***********************************************************
    #ifdef WITH_WEBENGINE
    ***********************************************************/
    private WebView web_view;

    /***********************************************************
    ***********************************************************/
    private Gtk.Label error_label;
    private Gtk.Label info_label;
    private Gtk.Box layout;
    private Gtk.Box container_layout;
    private HeaderBanner header_banner;


    internal signal void signal_url_catched (string user, string pass, string host);
    internal signal void signal_style_changed ();
    internal signal void signal_activate ();
    internal signal void signal_close ();

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsDialog (LibSync.Account account, bool use_flow2, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.use_flow2 = use_flow2;
        this.flow_2_auth_widget = null;
    //  #ifdef WITH_WEBENGINE
        this.web_view = null;
    //  #endif // WITH_WEBENGINE
        window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);

        this.layout = new Gtk.Box (Gtk.Orientation.VERTICAL);
        int spacing = this.layout.spacing ();
        int margin = this.layout.margin ();
        this.layout.spacing (0);
        this.layout.margin (0);

        this.container_layout = new Gtk.Box (Gtk.Orientation.VERTICAL);
        this.container_layout.spacing (spacing);
        this.container_layout.margin (margin);

        this.info_label = new Gtk.Label ();
        this.info_label.alignment (GLib.AlignCenter);
        this.container_layout.add_widget (this.info_label);

        if (this.use_flow2) {
            this.flow_2_auth_widget = new Flow2AuthWidget ();
            this.container_layout.add_widget (this.flow_2_auth_widget);

            this.flow_2_auth_widget.signal_auth_result.connect (
                this.on_signal_flow_2_auth_result
            );

            // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
            this.signal_style_changed.connect (
                this.flow_2_auth_widget.on_signal_style_changed
            );

            // allow Flow2 page to poll on window activation
            this.signal_activate.connect (
                this.flow_2_auth_widget.on_signal_poll_now
            );

            this.flow_2_auth_widget.start_auth (account);
        } else {
    //  #ifdef WITH_WEBENGINE
            this.web_view = new WebView ();
            this.container_layout.add_widget (this.web_view);

            this.web_view.signal_url_catched.connect (
                this.on_signal_url_catched
            );
    //  #endif // WITH_WEBENGINE
        }

        var app = (Application)GLib.Application;
        app.signal_is_showing_settings_dialog.connect (
            this.on_signal_show_settings_dialog
        );

        this.error_label = new Gtk.Label ();
        this.error_label.hide ();
        this.container_layout.add_widget (this.error_label);

        WizardCommon.init_error_label (this.error_label);

        this.layout.add_layout (this.container_layout);

        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void url (GLib.Uri url) {
    //  #ifdef WITH_WEBENGINE
        if (this.web_view != null) {
            this.web_view.url (url);
        }
    //  #else // WITH_WEBENGINE
        //  Q_UNUSED (url);
    //  #endif // WITH_WEBENGINE
    }


    /***********************************************************
    ***********************************************************/
    public void info (string message) {
        this.info_label.on_signal_text (message);
    }


    /***********************************************************
    ***********************************************************/
    public void error (string error) {
        // bring window to top
        on_signal_show_settings_dialog ();

        if (this.use_flow2 && this.flow_2_auth_widget) {
            this.flow_2_auth_widget.error (error);
            return;
        }

        if (error == "") {
            this.error_label.hide ();
        } else {
            this.error_label.on_signal_text (error);
            this.error_label.show ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool is_using_flow2 () {
        return this.use_flow2;
    }


    /***********************************************************
    ***********************************************************/
    protected override void close_event (GLib.CloseEvent e) {
        //  Q_UNUSED (e)

    //  #ifdef WITH_WEBENGINE
        if (this.web_view != null) {
            // Force calling WebView.~WebView () earlier so that this.profile and this.page are
            // deleted in the correct order.
            this.web_view.delete_later ();
            this.web_view = null;
        }
    //  #endif // WITH_WEBENGINE

        if (this.flow_2_auth_widget != null) {
            this.flow_2_auth_widget.reset_auth ();
            this.flow_2_auth_widget.delete_later ();
            this.flow_2_auth_widget = null;
        }

        signal_close ();
    }


    /***********************************************************
    ***********************************************************/
    protected void change_event (Gdk.Event e) {
        switch (e.type) {
        case Gdk.Event.StyleChange:
        case Gdk.Event.PaletteChange:
        case Gdk.Event.ThemeChange:
            customize_style ();

            // Notify the other widgets (Dark-/Light-Mode switching)
            signal_style_changed ();
            break;
        case Gdk.Event.ActivationChange:
            if (is_active_window ())
                signal_activate ();
            break;
        default:
            break;
        }

        Gtk.Dialog.change_event (e);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_flow_2_auth_result (Flow2Auth.Result r, string error_string, string user, string app_password) {
        //  Q_UNUSED (error_string)
        if (r == Flow2Auth.Result.LOGGED_IN) {
            signal_url_caught (user, app_password, "");
        } else {
            // bring window to top
            on_signal_show_settings_dialog ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_show_settings_dialog () {
        // bring window to top but slightly delay, to avoid being hidden behind the SettingsDialog
        GLib.Timeout.add (100, this.on_signal_show_delayed);
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_show_delayed () {
        OwncloudGui.raise_dialog (this);
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        // HINT: Customize dialog's own style here, if necessary in the future (Dark-/Light-Mode switching)
    }

} // class WebFlowCredentialsDialog

} // namespace Ui
} // namespace Occ
