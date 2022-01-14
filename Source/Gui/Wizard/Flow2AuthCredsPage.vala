/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariant>
// #include <QVBoxLayout>

// #pragma once

// #include <QList>
// #include <QMap>
// #include <QNetworkCookie>
// #include <QUrl>
// #include <QPointer>


namespace Occ {


class Flow2Auth_creds_page : Abstract_credentials_wizard_page {
public:
    Flow2Auth_creds_page ();

    AbstractCredentials *get_credentials () const override;

    void initialize_page () override;
    void cleanup_page () override;
    int next_id () const override;
    void set_connected ();
    bool is_complete () const override;

public slots:
    void slot_flow_2_auth_result (Flow2Auth.Result, string &error_string, string &user, string &app_password);
    void slot_poll_now ();
    void slot_style_changed ();

signals:
    void connect_to_oCUrl (string &);
    void poll_now ();
    void style_changed ();

public:
    string _user;
    string _app_password;

private:
    Flow2AuthWidget *_flow_2_auth_widget = nullptr;
    QVBoxLayout *_layout = nullptr;
};

    Flow2Auth_creds_page.Flow2Auth_creds_page ()
        : Abstract_credentials_wizard_page () {
        _layout = new QVBoxLayout (this);

        _flow_2_auth_widget = new Flow2AuthWidget ();
        _layout.add_widget (_flow_2_auth_widget);

        connect (_flow_2_auth_widget, &Flow2AuthWidget.auth_result, this, &Flow2Auth_creds_page.slot_flow_2_auth_result);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &Flow2Auth_creds_page.style_changed, _flow_2_auth_widget, &Flow2AuthWidget.slot_style_changed);

        // allow Flow2 page to poll on window activation
        connect (this, &Flow2Auth_creds_page.poll_now, _flow_2_auth_widget, &Flow2AuthWidget.slot_poll_now);
    }

    void Flow2Auth_creds_page.initialize_page () {
        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        oc_wizard.account ().set_credentials (CredentialsFactory.create ("http"));

        if (_flow_2_auth_widget)
            _flow_2_auth_widget.start_auth (oc_wizard.account ().data ());

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();

        _flow_2_auth_widget.slot_style_changed ();
    }

    void Occ.Flow2Auth_creds_page.cleanup_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        if (_flow_2_auth_widget)
            _flow_2_auth_widget.reset_auth ();

        // Forget sensitive data
        _app_password.clear ();
        _user.clear ();
    }

    void Flow2Auth_creds_page.slot_flow_2_auth_result (Flow2Auth.Result r, string &error_string, string &user, string &app_password) {
        Q_UNUSED (error_string)
        switch (r) {
        case Flow2Auth.NotSupported : {
            /* Flow2Auth not supported (can't open browser) */
            wizard ().show ();

            /* Don't fallback to HTTP credentials */
            /*OwncloudWizard *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.back ();
            oc_wizard.set_auth_type (DetermineAuthTypeJob.Basic);*/
            break;
        }
        case Flow2Auth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            wizard ().show ();
            break;
        case Flow2Auth.LoggedIn : {
            _user = user;
            _app_password = app_password;
            auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            Q_ASSERT (oc_wizard);

            emit connect_to_oCUrl (oc_wizard.account ().url ().to_string ());
            break;
        }
        }
    }

    int Flow2Auth_creds_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    void Flow2Auth_creds_page.set_connected () {
        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);

        // bring wizard to top
        oc_wizard.bring_to_top ();
    }

    AbstractCredentials *Flow2Auth_creds_page.get_credentials () {
        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        return new WebFlowCredentials (
                    _user,
                    _app_password,
                    oc_wizard._client_ssl_certificate,
                    oc_wizard._client_ssl_key,
                    oc_wizard._client_ssl_ca_certificates
        );
    }

    bool Flow2Auth_creds_page.is_complete () {
        return false; /* We can never go forward manually */
    }

    void Flow2Auth_creds_page.slot_poll_now () {
        emit poll_now ();
    }

    void Flow2Auth_creds_page.slot_style_changed () {
        emit style_changed ();
    }

    } // namespace Occ
    