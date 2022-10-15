/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@author Krzesimir Nowak <krzesimir@endocode.com>

@copyright GPLv??? or later
***********************************************************/

//  #include <GLib.Dir>
//  #include <GLib.FileDialog>
//  #include <GLib.PushButton>
//  #include <Gtk.MessageBox>
//  #include <GLib.Ssl>
//  #include <GLib.TlsCertificate>
//  #include <Soup.Context>
//  #include <GLib.PropertyAnimation>
//  #include <GLib.Graphics_pixmap_item>
//  #include <GLib.OutputStream>
//  #include <GLib.Wizard>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudSetupPage class
@ingroup gui
***********************************************************/
public class OwncloudSetupPage { //: GLib.WizardPage {
    /***********************************************************
    ***********************************************************/
    private OwncloudSetupPage instance;

    /***********************************************************
    ***********************************************************/
    private string oc_url;
    private string oc_user;
    private bool auth_type_known = false;
    private bool checking = false;
    private LibSync.DetermineAuthTypeJob.AuthType auth_type = LibSync.DetermineAuthTypeJob.AuthType.BASIC;

    /***********************************************************
    ***********************************************************/
    private GLib.ProgressIndicator progress_indicator;
    private OwncloudWizard oc_wizard;
    private AddCertificateDialog add_certificate_dialog = null;


    internal signal void signal_determine_auth_type (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudSetupPage (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base ();
        //  this.progress_indicator = new GLib.ProgressIndicator (this);
        //  this.oc_wizard = (OwncloudWizard)parent;
        //  this.instance.up_ui (this);

        //  setup_server_address_description_label ();

        //  LibSync.Theme theme = LibSync.Theme.instance;
        //  if (theme.override_server_url == "") {
        //      this.instance.le_url.postfix (theme.wizard_url_postfix);
        //      this.instance.le_url.placeholder_text (theme.WIZARD_URL_HINT);
        //  } else if (LibSync.Theme.force_override_server_url) {
        //      this.instance.le_url.enabled (false);
        //  }

        //  register_field ("OcsUrl*", this.instance.le_url);

        //  var size_policy = this.progress_indicator.size_policy ();
        //  size_policy.retain_size_when_hidden (true);
        //  this.progress_indicator.size_policy (size_policy);

        //  this.instance.progress_layout.add_widget (this.progress_indicator);
        //  on_signal_stop_spinner ();

        //  set_up_customization ();

        //  on_signal_url_changed (""); // don't jitter UI

        //  this.instance.le_url.text_changed.connect (
        //      this.on_signal_url_changed
        //  );
        //  this.instance.le_url.editing_finished.connect (
        //      this.on_signal_url_edit_finished
        //  );

        //  add_certificate_dialog = new AddCertificateDialog (this);
        //  add_certificate_dialog.accepted.connect (
        //      this.on_signal_certificate_accepted
        //  );
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete {
        public get {
            return this.instance.le_url.text () != "" && !this.checking;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        //  customize_style ();

        //  WizardCommon.init_error_label (this.instance.error_label);

        //  this.auth_type_known = false;
        //  this.checking = false;

        //  GLib.AbstractButton next_button = wizard ().button (GLib.Wizard.NextButton);
        //  var push_button = (GLib.PushButton)next_button;
        //  if (push_button) {
        //      push_button.default (true);
        //  }

        //  this.instance.le_url.focus ();

        //  var is_server_url_overridden = !LibSync.Theme.override_server_url = "";
        //  if (is_server_url_overridden && !LibSync.Theme.force_override_server_url) {
        //      // If the url is overwritten but we don't force to use that url
        //      // Just focus the next button to let the user navigate quicker
        //      if (next_button) {
        //          next_button.focus ();
        //      }
        //  } else if (is_server_url_overridden) {
        //      // If the overwritten url is not empty and we force this overwritten url
        //      // we just check the server type and switch to next page
        //      // immediately.
        //      commit_page (true);
        //      // Hack : commit_page () changes caption, but after an error this page could still be visible
        //      button_text (GLib.Wizard.Commit_button, _("&Next >"));
        //      validate_page ();
        //      visible (false);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        //  if (!this.auth_type_known) {
        //      on_signal_url_edit_finished ();
        //      string u = this.url;
        //      GLib.Uri qurl = new GLib.Uri (u);
        //      if (!qurl.is_valid || qurl.host () == "") {
        //          on_signal_error_string (_("Server address does not seem to be valid"), false);
        //          return false;
        //      }

        //      on_signal_error_string ("", false);
        //      this.checking = true;
        //      on_signal_start_spinner ();
        //      signal_complete_changed ();

        //      signal_determine_auth_type (u);
        //      return false;
        //  } else {
        //      // connecting is running
        //      on_signal_stop_spinner ();
        //      this.checking = false;
        //      signal_complete_changed ();
        //      return true;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public int next_id {
        public get {
            switch (this.auth_type) {
            case DetermineAuthTypeJob.AuthType.BASIC:
                return WizardCommon.Pages.PAGE_HTTP_CREDS;
            case DetermineAuthTypeJob.AuthType.OAUTH:
                return WizardCommon.Pages.PAGE_OAUTH_CREDS;
            case DetermineAuthTypeJob.AuthType.LOGIN_FLOW_V2:
                return WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS;
        //  #ifdef WITH_WEBENGINE
            case DetermineAuthTypeJob.WEB_VIEW_FLOW:
                return WizardCommon.Pages.PAGE_WEB_VIEW;
        //  #endif WITH_WEBENGINE
            case DetermineAuthTypeJob.NO_AUTH_TYPE:
                return WizardCommon.Pages.PAGE_HTTP_CREDS;
            }
            GLib.assert_not_reached ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void server_url (string new_url) {
        //  this.oc_wizard.registration = false;
        //  this.oc_url = new_url;
        //  if (this.oc_url == "") {
        //      this.instance.le_url = "";
        //      return;
        //  }

        //  this.instance.le_url.on_signal_text (this.oc_url);
    }


    /***********************************************************
    ***********************************************************/
    //  public void allow_password_storage (bool);


    /***********************************************************
    ***********************************************************/
    public string url {
        public get {
            return this.instance.le_url.full_text ().simplified ();
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public void on_signal_remote_folder (string remote_fo);


    /***********************************************************
    ***********************************************************/
    public void on_signal_auth_type (DetermineAuthTypeJob.AuthType type) {
        //  this.auth_type_known = true;
        //  this.auth_type = type;
        //  on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string err, bool retry_http_only) {
        //  if (err == "") {
        //      this.instance.error_label.visible (false);
        //  } else {
        //      if (retry_http_only) {
        //          GLib.Uri url = new GLib.Uri (this.instance.le_url.full_text ());
        //          if (url.scheme () == "https") {
        //              // Ask the user how to proceed when connecting to a https:// URL fails.
        //              // It is possible that the server is secured with client-side TLS certificates,
        //              // but that it has no way of informing the owncloud client that this is the case.

        //              OwncloudConnectionMethodDialog dialog;
        //              dialog.url (url);
        //              // FIXME: Synchronous dialogs are not so nice because of event loop recursion
        //              int ret_val = dialog.exec ();

        //              switch (ret_val) {
        //              case OwncloudConnectionMethodDialog.Method.NO_TLS: {
        //                  url.scheme ("http");
        //                  this.instance.le_url.full_text (url.to_string ());
        //                  // skip ahead to next page, since the user would expect us to retry automatically
        //                  wizard ().next ();
        //              } break;
        //              case OwncloudConnectionMethodDialog.Method.CLIENT_SIDE_TLS:
        //                  add_certificate_dialog.show ();
        //                  break;
        //              case OwncloudConnectionMethodDialog.Method.CLOSED:
        //              case OwncloudConnectionMethodDialog.Method.BACK:
        //              default:
        //                  // No-operation.
        //                  break;
        //              }
        //          }
        //      }

        //      this.instance.error_label.visible (true);
        //      this.instance.error_label.on_signal_text (err);
        //  }
        //  this.checking = false;
        //  signal_complete_changed ();
        //  on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start_spinner () {
        //  this.instance.progress_layout.enabled (true);
        //  this.progress_indicator.visible (true);
        //  this.progress_indicator.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_stop_spinner () {
        //  this.instance.progress_layout.enabled (false);
        //  this.progress_indicator.visible (false);
        //  this.progress_indicator.on_signal_stop_animation ();
    }


    /***********************************************************
    Called during the validation of the client certificate.
    ***********************************************************/
    public void on_signal_certificate_accepted () {
        //  GLib.File cert_file = new GLib.File (add_certificate_dialog.certificate_path);
        //  cert_file.open (GLib.File.ReadOnly);
        //  string cert_data = cert_file.read_all ();
        //  string cert_password = add_certificate_dialog.certificate_password ().to_local8Bit ();

        //  GLib.OutputStream cert_data_buffer = new GLib.OutputStream (cert_data);
        //  cert_data_buffer.open (GLib.IODevice.ReadOnly);
        //  if (GLib.TlsCertificate.import_pkcs12 (cert_data_buffer,
        //          this.oc_wizard.client_ssl_key, this.oc_wizard.client_ssl_certificate,
        //          this.oc_wizard.client_ssl_ca_certificates, cert_password)) {
        //      this.oc_wizard.client_cert_bundle = cert_data;
        //      this.oc_wizard.client_cert_password = cert_password;

        //      add_certificate_dialog.reinit (); // FIXME: Why not just have this only created on use?

        //      // The extracted SSL key and cert gets added to the GLib.TlsConfiguration in check_server ()
        //      validate_page ();
        //  } else {
        //      add_certificate_dialog.show_error_message (_("Could not load certificate. Maybe wrong password?"));
        //      add_certificate_dialog.show ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        //  customize_style ();
    }


    /***********************************************************
    Slot hit from text_changed of the url entry field.
    ***********************************************************/
    protected void on_signal_url_changed (string url) {
        //  // Need to set next button as default button here because
        //  // otherwise the on OSX the next button does not stay the default
        //  // button
        //  var next_button = (GLib.PushButton)this.oc_wizard.button (GLib.Wizard.NextButton);
        //  if (next_button) {
        //      next_button.default (true);
        //  }

        //  this.auth_type_known = false;

        //  string new_url = url;
        //  if (url.has_suffix ("index.php")) {
        //      new_url.chop (9);
        //  }
        //  if (this.oc_wizard && this.oc_wizard.account) {
        //      string web_dav_path = this.oc_wizard.account.dav_path;
        //      if (url.has_suffix (web_dav_path)) {
        //          new_url.chop (web_dav_path.length);
        //      }
        //      if (web_dav_path.has_suffix ("/")) {
        //          web_dav_path.chop (1); // cut off the slash
        //          if (url.has_suffix (web_dav_path)) {
        //              new_url.chop (web_dav_path.length);
        //          }
        //      }
        //  }
        //  if (new_url != url) {
        //      this.instance.le_url.on_signal_text (new_url);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_url_edit_finished () {
        //  string url = this.instance.le_url.full_text ();
        //  if (GLib.Uri (url).is_relative () && !url == "") {
        //      // no scheme defined, set one
        //      url.prepend ("https://");
        //      this.instance.le_url.full_text (url);
        //  }
    }


    /***********************************************************
    ***********************************************************/
    protected void set_up_customization () {
        //  // set defaults for the customize labels.
        //  this.instance.top_label.hide ();
        //  this.instance.bottom_label.hide ();

        //  LibSync.Theme theme = LibSync.Theme.instance;
        //  GLib.Variant variant = theme.custom_media (LibSync.Theme.CustomMediaType.OC_SETUP_TOP);
        //  if (!variant == null) {
        //      WizardCommon.set_up_custom_media (variant, this.instance.top_label);
        //  }

        //  variant = theme.custom_media (LibSync.Theme.CustomMediaType.OC_SETUP_BOTTOM);
        //  WizardCommon.set_up_custom_media (variant, this.instance.bottom_label);

        //  var le_url_palette = this.instance.le_url.palette ();
        //  le_url_palette.on_signal_color (Gtk.Palette.Text, GLib.black);
        //  le_url_palette.on_signal_color (Gtk.Palette.Base, GLib.white);
        //  this.instance.le_url.palette (le_url_palette);
    }


    /***********************************************************
    ***********************************************************/
    private void logo () {
        //  this.instance.logo_label.pixmap (LibSync.Theme.wizard_application_logo);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        //  logo ();

        //  if (this.progress_indicator) {
        //      var is_dark_background = LibSync.Theme.is_dark_color (palette ().window ().color ());
        //      if (is_dark_background) {
        //          this.progress_indicator.on_signal_color (GLib.white);
        //      } else {
        //          this.progress_indicator.on_signal_color (GLib.black);
        //      }
        //  }

        //  WizardCommon.customize_hint_label (this.instance.server_address_description_label);
    }


    /***********************************************************
    ***********************************************************/
    private void setup_server_address_description_label () {
        //  var app_name = LibSync.Theme.app_name_gui;
        //  this.instance.server_address_description_label.on_signal_text (_("The link to your %1 web interface when you open it in the browser.", "%1 will be replaced with the application name").printf (app_name));
    }


    /***********************************************************
    ***********************************************************/
    private static string subject_info_helper (GLib.TlsCertificate cert, string qa) {
        //  return cert.subject_info (qa).join ("/");
    }

} // class OwncloudSetupPage

} // namespace Ui
} // namespace Occ
    