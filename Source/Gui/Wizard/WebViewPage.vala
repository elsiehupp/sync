
// #include <QWeb_engine_url_request_job>
// #include <QProgressBar>
// #include <QVBoxLayout>
// #include <QNetworkProxyFactory>
// #include <QScreen>

namespace Occ {


class Web_view_page : Abstract_credentials_wizard_page {
public:
    Web_view_page (Gtk.Widget *parent = nullptr);
    ~Web_view_page () override;

    void initialize_page () override;
    void cleanup_page () override;
    int next_id () const override;
    bool is_complete () const override;

    AbstractCredentials* get_credentials () const override;
    void set_connected ();

signals:
    void connect_to_oCUrl (string&);

private slots:
    void url_catched (string user, string pass, string host);

private:
    void resize_wizard ();
    bool try_to_set_wizard_size (int width, int height);

    OwncloudWizard *_oc_wizard;
    WebView *_web_view;

    string _user;
    string _pass;

    bool _use_system_proxy;

    QSize _original_wizard_size;
};


    Web_view_page.Web_view_page (Gtk.Widget *parent)
        : Abstract_credentials_wizard_page () {
        _oc_wizard = qobject_cast<OwncloudWizard> (parent);

        q_c_info (lc_wizard_webiew_page ()) << "Time for a webview!";
        _web_view = new WebView (this);

        auto *layout = new QVBoxLayout (this);
        layout.set_margin (0);
        layout.add_widget (_web_view);
        set_layout (layout);

        connect (_web_view, &WebView.url_catched, this, &Web_view_page.url_catched);

        //_use_system_proxy = QNetworkProxyFactory.uses_system_configuration ();
    }

    Web_view_page.~Web_view_page () = default;
    //{
    //    QNetworkProxyFactory.set_use_system_configuration (_use_system_proxy);
    //}

    void Web_view_page.initialize_page () {
        //QNetworkProxy.set_application_proxy (QNetworkProxy.application_proxy ());

        string url;
        if (_oc_wizard.registration ()) {
            url = "https://nextcloud.com/register";
        } else {
            url = _oc_wizard.oc_url ();
            if (!url.ends_with ('/')) {
                url += "/";
            }
            url += "index.php/login/flow";
        }
        q_c_info (lc_wizard_webiew_page ()) << "Url to auth at : " << url;
        _web_view.set_url (QUrl (url));

        _original_wizard_size = _oc_wizard.size ();
        resize_wizard ();
    }

    void Web_view_page.resize_wizard () {
        // The webview needs a little bit more space
        auto wizard_size_changed = try_to_set_wizard_size (_original_wizard_size.width () * 2, _original_wizard_size.height () * 2);

        if (!wizard_size_changed) {
            wizard_size_changed = try_to_set_wizard_size (static_cast<int> (_original_wizard_size.width () * 1.5), static_cast<int> (_original_wizard_size.height () * 1.5));
        }

        if (wizard_size_changed) {
            _oc_wizard.center_window ();
        }
    }

    bool Web_view_page.try_to_set_wizard_size (int width, int height) {
        const auto window = _oc_wizard.window ();
        const auto screen_geometry = QGuiApplication.screen_at (window.pos ()).geometry ();
        const auto window_width = screen_geometry.width ();
        const auto window_height = screen_geometry.height ();

        if (width < window_width && height < window_height) {
            _oc_wizard.resize (width, height);
            return true;
        }

        return false;
    }

    void Web_view_page.cleanup_page () {
        _oc_wizard.resize (_original_wizard_size);
        _oc_wizard.center_window ();
    }

    int Web_view_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    bool Web_view_page.is_complete () {
        return false;
    }

    AbstractCredentials* Web_view_page.get_credentials () {
        return new WebFlowCredentials (_user, _pass, _oc_wizard._client_ssl_certificate, _oc_wizard._client_ssl_key);
    }

    void Web_view_page.set_connected () {
        q_c_info (lc_wizard_webiew_page ()) << "YAY! we are connected!";
    }

    void Web_view_page.url_catched (string user, string pass, string host) {
        q_c_info (lc_wizard_webiew_page ()) << "Got user : " << user << ", server : " << host;

        _user = user;
        _pass = pass;

        AccountPtr account = _oc_wizard.account ();
        account.set_url (host);

        q_c_info (lc_wizard_webiew_page ()) << "URL : " << field ("OCUrl").to_string ();
        emit connect_to_oCUrl (host);
    }

    }
    