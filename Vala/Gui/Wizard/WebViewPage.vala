
//  #include <GLib.WebEngineUrlRequestJob>
//  #include <GLib.ProgressBar>
//  #include <Soup.NetworkProxyFactory>
//  #include <Gdk.Monitor>

namespace Occ {
namespace Ui {

public class WebViewPage : AbstractCredentialsWizardPage {

    //  /***********************************************************
    //  ***********************************************************/
    //  private OwncloudWizard oc_wizard;

    //  /***********************************************************
    //  ***********************************************************/
    //  private string pass;

    //  /***********************************************************
    //  ***********************************************************/
    //  private bool use_system_proxy;

    //  /***********************************************************
    //  ***********************************************************/
    //  private Gdk.Rectangle original_wizard_size;

    //  /***********************************************************
    //  ***********************************************************/
    //  internal signal void signal_connect_to_ocs_url (string value);

    //  /***********************************************************
    //  ***********************************************************/
    //  public WebViewPage (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base ();
        //  this.oc_wizard = (OwncloudWizard)parent;

        //  GLib.info ("Time for a webview!");
        //  this.web_view = new WebView (this);

        //  var layout = new Gtk.Box (Gtk.Orientation.VERTICAL);
        //  layout.margin (0);
        //  layout.add_widget (this.web_view);
        //  layout (layout);

        //  this.web_view.signal_url_catched.connect (
        //      this.on_signal_url_catched
        //  );

        //  // this.use_system_proxy = Soup.NetworkProxyFactory.uses_system_configuration ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  //  ~WebViewPage () = default;
    //  //  {
    //  //    Soup.NetworkProxyFactory.use_system_configuration (this.use_system_proxy);
    //  //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void initialize_page () {
        //  //  Soup.NetworkProxy.application_proxy (Soup.NetworkProxy.application_proxy ());

        //  string url;
        //  if (this.oc_wizard.registration ()) {
        //      url = "https://nextcloud.com/register";
        //  } else {
        //      url = this.oc_wizard.oc_url ();
        //      if (!url.has_suffix ("/")) {
        //          url += "/";
        //      }
        //      url += "index.php/login/flow";
        //  }
        //  GLib.info ("Url to auth at: " + url);
        //  this.web_view.url (GLib.Uri (url));

        //  this.original_wizard_size = this.oc_wizard.size ();
        //  resize_wizard ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void clean_up_page () {
        //  this.oc_wizard.resize (this.original_wizard_size);
        //  this.oc_wizard.center_window ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public int next_id {
        //  public get {
        //      return WizardCommon.Pages.PAGE_ADVANCED_SETUP;
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool is_complete {
        //  public get {
        //      return false;
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public AbstractCredentials credentials {
        //  public get {
        //      return new WebFlowCredentials (this.user, this.pass, this.oc_wizard.client_ssl_certificate, this.oc_wizard.client_ssl_key);
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void connected () {
        //  GLib.info ("YAY! we are connected!");
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_url_catched (string user, string pass, string host) {
        //  GLib.info ("Got user: " + user + ", server: " + host);

        //  this.user = user;
        //  this.pass = pass;

        //  LibSync.Account account = this.oc_wizard.account;
        //  account.url (host);

        //  GLib.info ("URL: " + field ("OcsUrl").to_string ());
        //  signal_connect_to_ocs_url (host);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private bool try_to_wizard_size (int width, int height) {
        //  var window = this.oc_wizard.window ();
        //  var screen_geometry = GLib.Application.screen_at (window.position ()).geometry ();
        //  var window_width = screen_geometry.width ();
        //  var window_height = screen_geometry.height ();

        //  if (width < window_width && height < window_height) {
        //      this.oc_wizard.resize (width, height);
        //      return true;
        //  }

        //  return false;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void resize_wizard () {
        //  // The webview needs a little bit more space
        //  var wizard_size_changed = try_to_wizard_size (this.original_wizard_size.width () * 2, this.original_wizard_size.height () * 2);

        //  if (!wizard_size_changed) {
        //      wizard_size_changed = try_to_wizard_size ((int)(this.original_wizard_size.width () * 1.5), (int)(this.original_wizard_size.height () * 1.5));
        //  }

        //  if (wizard_size_changed) {
        //      this.oc_wizard.center_window ();
        //  }
    //  }

} // class WebViewPage

} // namespace Ui
} // namespace Occ
