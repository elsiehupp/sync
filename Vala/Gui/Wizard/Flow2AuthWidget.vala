/***********************************************************
@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

public class Flow2AuthWidget { //: Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private LibSync.Account account = null;
    private Flow2Auth async_auth;
    private static Flow2AuthWidget instance;

    /***********************************************************
    ***********************************************************/
    private GLib.ProgressIndicator progress_indicator;
    private int status_update_skip_count = 0;

    internal signal void signal_auth_result (Flow2Auth.Result result, string error_string, string user, string app_password);
    internal signal void signal_poll_now ();

    /***********************************************************
    ***********************************************************/
    public Flow2AuthWidget (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base ();
        //  this.progress_indicator = new GLib.ProgressIndicator (this);
        //  Flow2AuthWidget.instance.setupUi (this);

        //  WizardCommon.initErrorLabel (Flow2AuthWidget.instance.error_label);
        //  Flow2AuthWidget.instance.error_label.setTextFormat (GLib.RichText);

        //  Flow2AuthWidget.instance.open_link_label.clicked.connect (
        //      this.on_signal_open_browser
        //  );
        //  Flow2AuthWidget.instance.copy_link_label.clicked.connect (
        //      this.on_signal_copy_link_to_clipboard
        //  );

        //  var size_policy = this.progress_indicator.size_policy ();
        //  size_policy.retain_size_when_hidden (true);
        //  this.progress_indicator.setSizePolicy (size_policy);

        //  Flow2AuthWidget.instance.progress_layout.add_widget (this.progress_indicator);
        //  stop_spinner (false);

        //  customize_style ();
    }


    ~Flow2AuthWidget () {
        //  // Forget sensitive data
        //  this.async_auth.reset ();
    }


    /***********************************************************
    ***********************************************************/
    public void start_auth (LibSync.Account account) {
        //  Flow2Auth old_auth = this.async_auth.take ();
        //  if (old_auth) {
        //      old_auth.deleteLater ();
        //  }

        //  this.status_update_skip_count = 0;

        //  this.account = account;

        //  this.async_auth.reset (new Flow2Auth (this.account, this));
        //  this.async_auth.signal_result.connect (
        //      this.on_signal_auth_result // GLib.QueuedConnection
        //  );
        //  this.async_auth.signal_status_changed.connect (
        //      this.on_signal_status_changed
        //  );
        //  this.signal_poll_now.connect (
        //      this.async_auth.on_signal_poll_now
        //  );
        //  this.async_auth.start ();
    }


    /***********************************************************
    ***********************************************************/
    public void reauth (LibSync.Account account) {
        //  start_auth (account);
    }


    /***********************************************************
    ***********************************************************/
    public void error (string error) {
        //  if (error == "") {
        //      Flow2AuthWidget.instance.error_label.hide ();
        //  } else {
        //      Flow2AuthWidget.instance.error_label.text (error);
        //      Flow2AuthWidget.instance.error_label.show ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_auth_result (Flow2Auth.Result r, string error_string, string user, string application_password) {
        //  stop_spinner (false);

        //  switch (r) {
        //  case Flow2Auth.NotSupported:
        //      /* Flow2Auth can't open browser */
        //      Flow2AuthWidget.instance.error_label.text (_("Unable to open the Browser, please copy the link to your Browser."));
        //      Flow2AuthWidget.instance.error_label.show ();
        //      break;
        //  case Flow2Auth.Error:
        //      /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
        //      Flow2AuthWidget.instance.error_label.text (error_string);
        //      Flow2AuthWidget.instance.error_label.show ();
        //      break;
        //  case Flow2Auth.LoggedIn: {
        //      Flow2AuthWidget.instance.error_label.hide ();
        //      break;
        //  }
        //  }

        //  signal_auth_result (r, error_string, user, application_password);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now () {
        //  signal_poll_now ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_status_changed (Flow2Auth.PollStatus status, int64 seconds_left) {
        //  switch (status) {
        //  case Flow2Auth.statusPollCountdown:
        //      if (this.status_update_skip_count > 0) {
        //          this.status_update_skip_count--;
        //          break;
        //      }
        //      Flow2AuthWidget.instance.status_label.setext (_("Waiting for authorization") + "… (%1)".printf (secondsLeft));
        //      stop_spinner (true);
        //      break;
        //  case Flow2Auth.statusPollNow:
        //      this.status_update_skip_count = 0;
        //      Flow2AuthWidget.instance.status_label.text (_("Polling for authorization") + "…");
        //      startSpinner ();
        //      break;
        //  case Flow2Auth.statusFetchToken:
        //      this.status_update_skip_count = 0;
        //      Flow2AuthWidget.instance.status_label.text (_("Starting authorization") + "…");
        //      startSpinner ();
        //      break;
        //  case Flow2Auth.statusCopyLinkToClipboard:
        //      Flow2AuthWidget.instance.status_label.text (_("Link copied to clipboard."));
        //      this.status_update_skip_count = 3;
        //      stop_spinner (true);
        //      break;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        //  customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_browser () {
        //  if (Flow2AuthWidget.instance.error_label != null) {
        //      Flow2AuthWidget.instance.error_label.hide ();
        //  }

        //  if (this.async_auth != null) {
        //      this.async_auth.open_browser ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_copy_link_to_clipboard () {
        //  if (Flow2AuthWidget.instance.error_label != null) {
        //      Flow2AuthWidget.instance.error_label.hide ();
        //  }

        //  if (this.async_auth != null) {
        //      this.async_auth.copy_link_to_clipboard ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_spinner () {
        //  Flow2AuthWidget.instance.progress_layout.enabled (true);
        //  Flow2AuthWidget.instance.status_label.visible (true);
        //  this.progress_indicator.visible (true);
        //  this.progress_indicator.start_animation ();

        //  Flow2AuthWidget.instance.open_link_label.enabled (false);
        //  Flow2AuthWidget.instance.copy_link_label.enabled (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner (bool show_status_label) {
        //  Flow2AuthWidget.instance.progress_layout.enabled (false);
        //  Flow2AuthWidget.instance.status_label.visible (show_status_label);
        //  this.progress_indicator.visible (false);
        //  this.progress_indicator.stop_animation ();

        //  Flow2AuthWidget.instance.open_link_label.enabled (this.status_update_skip_count == 0);
        //  Flow2AuthWidget.instance.copy_link_label.enabled (this.status_update_skip_count == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        //  logo ();

        //  if (this.progress_indicator != null) {
        //      bool is_dark_background = LibSync.Theme.is_dark_color (palette ().window ().color ());
        //      if (this.is_dark_background) {
        //          this.progress_indicator.color (GLib.white);
        //      } else {
        //          this.progress_indicator.color (GLib.black);
        //      }
        //  }

        //  Flow2AuthWidget.instance.open_link_label.text (_("Reopen Browser"));
        //  Flow2AuthWidget.instance.open_link_label.alignment (GLib.AlignCenter);

        //  Flow2AuthWidget.instance.copy_link_label.text (_("Copy Link"));
        //  Flow2AuthWidget.instance.copy_link_label.alignment (GLib.AlignCenter);

        //  WizardCommon.customize_hint_label (Flow2AuthWidget.instance.status_label);
    }


    /***********************************************************
    ***********************************************************/
    private void logo () {
        //  var background_color = palette ().window ().color ();
        //  var logo_icon_filename = LibSync.Theme.is_branded
        //      ? LibSync.Theme.hidpi_filename ("external.png", background_color)
        //      : LibSync.Theme.hidpi_filename (":/client/theme/colored/external.png");
        //  Flow2AuthWidget.instance.logo_label.pixmap (logo_icon_filename);
    }

}

} // namespace Occ























} // namespace OCC
 