
//  #include <QWeb_engine_url_request_job>
//  #include <QProgressBar>
//  #include <QVBoxLayout>
//  #include <QNetworkProxyFactory>
//  #include <QScreen>

namespace Occ {


class Web_view_page : Abstract_credentials_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Web_view_page (Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public void initialize_page () override;
    public void cleanup_page () override;
    public int next_id () override;
    public bool is_complete () override;

    /***********************************************************
    ***********************************************************/
    public AbstractCredentials* get_credentials () override;
    public void set_connected ();

signals:
    void connect_to_oc_url (string&);


    /***********************************************************
    ***********************************************************/
    private void on_url_catched (string user, string pass, string host);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private bool try_to_set_wizard_size (int width, int height);

    /***********************************************************
    ***********************************************************/
    private OwncloudWizard this.oc_wizard;

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private string this.pass;

    /***********************************************************
    ***********************************************************/
    private bool this.use_system_proxy;

    /***********************************************************
    ***********************************************************/
    private QSize this.original_wizard_size;
}


    Web_view_page.Web_view_page (Gtk.Widget parent)
        : Abstract_credentials_wizard_page () {
        this.oc_wizard = qobject_cast<OwncloudWizard> (parent);

        GLib.info (lc_wizard_webiew_page ()) << "Time for a webview!";
        this.web_view = new WebView (this);

        var layout = new QVBoxLayout (this);
        layout.set_margin (0);
        layout.add_widget (this.web_view);
        set_layout (layout);

        connect (this.web_view, &WebView.on_url_catched, this, &Web_view_page.on_url_catched);

        //this.use_system_proxy = QNetworkProxyFactory.uses_system_configuration ();
    }

    Web_view_page.~Web_view_page () = default;
    //{
    //    QNetworkProxyFactory.set_use_system_configuration (this.use_system_proxy);
    //}

    void Web_view_page.initialize_page () {
        //QNetworkProxy.set_application_proxy (QNetworkProxy.application_proxy ());

        string url;
        if (this.oc_wizard.registration ()) {
            url = "https://nextcloud.com/register";
        } else {
            url = this.oc_wizard.oc_url ();
            if (!url.ends_with ('/')) {
                url += "/";
            }
            url += "index.php/login/flow";
        }
        GLib.info (lc_wizard_webiew_page ()) << "Url to auth at : " << url;
        this.web_view.set_url (GLib.Uri (url));

        this.original_wizard_size = this.oc_wizard.size ();
        resize_wizard ();
    }

    void Web_view_page.resize_wizard () {
        // The webview needs a little bit more space
        var wizard_size_changed = try_to_set_wizard_size (this.original_wizard_size.width () * 2, this.original_wizard_size.height () * 2);

        if (!wizard_size_changed) {
            wizard_size_changed = try_to_set_wizard_size (static_cast<int> (this.original_wizard_size.width () * 1.5), static_cast<int> (this.original_wizard_size.height () * 1.5));
        }

        if (wizard_size_changed) {
            this.oc_wizard.center_window ();
        }
    }

    bool Web_view_page.try_to_set_wizard_size (int width, int height) {
        const var window = this.oc_wizard.window ();
        const var screen_geometry = QGuiApplication.screen_at (window.position ()).geometry ();
        const var window_width = screen_geometry.width ();
        const var window_height = screen_geometry.height ();

        if (width < window_width && height < window_height) {
            this.oc_wizard.resize (width, height);
            return true;
        }

        return false;
    }

    void Web_view_page.cleanup_page () {
        this.oc_wizard.resize (this.original_wizard_size);
        this.oc_wizard.center_window ();
    }

    int Web_view_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    bool Web_view_page.is_complete () {
        return false;
    }

    AbstractCredentials* Web_view_page.get_credentials () {
        return new WebFlowCredentials (this.user, this.pass, this.oc_wizard.client_ssl_certificate, this.oc_wizard.client_ssl_key);
    }

    void Web_view_page.set_connected () {
        GLib.info (lc_wizard_webiew_page ()) << "YAY! we are connected!";
    }

    void Web_view_page.on_url_catched (string user, string pass, string host) {
        GLib.info (lc_wizard_webiew_page ()) << "Got user : " << user << ", server : " << host;

        this.user = user;
        this.pass = pass;

        AccountPointer account = this.oc_wizard.account ();
        account.set_url (host);

        GLib.info (lc_wizard_webiew_page ()) << "URL : " << field ("OCUrl").to_string ();
        /* emit */ connect_to_oc_url (host);
    }

    }
    