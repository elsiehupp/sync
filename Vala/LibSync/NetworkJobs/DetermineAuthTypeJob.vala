/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief Checks with auth type to use for a server
@ingroup libsync
***********************************************************/
class DetermineAuthTypeJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum AuthType {
        NoAuthType, // used only before we got a chance to probe the server
#ifdef WITH_WEBENGINE
        WebViewFlow,
#endif // WITH_WEBENGINE
        Basic, // also the catch-all fallback for backwards compatibility reasons
        OAuth,
        LoginFlowV2
    };
    Q_ENUM (AuthType)

    /***********************************************************
    ***********************************************************/
    public DetermineAuthTypeJob (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start ();
signals:
    void auth_type (AuthType);


    /***********************************************************
    ***********************************************************/
    private void check_all_done ();

    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private AuthType this.result_get = NoAuthType;
    private AuthType this.result_propfind = NoAuthType;
    private AuthType this.result_old_flow = NoAuthType;
    private bool this.get_done = false;
    private bool this.propfind_done = false;
    private bool this.old_flow_done = false;






    DetermineAuthTypeJob.DetermineAuthTypeJob (AccountPointer account, GLib.Object parent)
        : GLib.Object (parent)
        , this.account (account) {
    }

    void DetermineAuthTypeJob.on_start () {
        q_c_info (lc_determine_auth_type_job) << "Determining auth type for" << this.account.dav_url ();

        Soup.Request req;
        // Prevent HttpCredentialsAccessManager from setting an Authorization header.
        req.set_attribute (HttpCredentials.DontAddCredentialsAttribute, true);
        // Don't reuse previous auth credentials
        req.set_attribute (Soup.Request.AuthenticationReuseAttribute, Soup.Request.Manual);

        // Start three parallel requests

        // 1. determines whether it's a basic auth server
        var get = this.account.send_request ("GET", this.account.url (), req);

        // 2. checks the HTTP auth method.
        var propfind = this.account.send_request ("PROPFIND", this.account.dav_url (), req);

        // 3. Determines if the old flow has to be used (GS for now)
        var old_flow_required = new JsonApiJob (this.account, "/ocs/v2.php/cloud/capabilities", this);

        get.on_set_timeout (30 * 1000);
        propfind.on_set_timeout (30 * 1000);
        old_flow_required.on_set_timeout (30 * 1000);
        get.set_ignore_credential_failure (true);
        propfind.set_ignore_credential_failure (true);
        old_flow_required.set_ignore_credential_failure (true);

        connect (get, &SimpleNetworkJob.finished_signal, this, [this, get] () {
            const var reply = get.reply ();
            const var www_authenticate_header = reply.raw_header ("WWW-Authenticate");
            if (reply.error () == Soup.Reply.AuthenticationRequiredError
                && (www_authenticate_header.starts_with ("Basic") || www_authenticate_header.starts_with ("Bearer"))) {
                this.result_get = Basic;
            } else {
                this.result_get = LoginFlowV2;
            }
            this.get_done = true;
            check_all_done ();
        });
        connect (propfind, &SimpleNetworkJob.finished_signal, this, [this] (Soup.Reply reply) {
            var auth_challenge = reply.raw_header ("WWW-Authenticate").to_lower ();
            if (auth_challenge.contains ("bearer ")) {
                this.result_propfind = OAuth;
            } else {
                if (auth_challenge.is_empty ()) {
                    GLib.warn (lc_determine_auth_type_job) << "Did not receive WWW-Authenticate reply to auth-test PROPFIND";
                } else {
                    GLib.warn (lc_determine_auth_type_job) << "Unknown WWW-Authenticate reply to auth-test PROPFIND:" << auth_challenge;
                }
                this.result_propfind = Basic;
            }
            this.propfind_done = true;
            check_all_done ();
        });
        connect (old_flow_required, &JsonApiJob.json_received, this, [this] (QJsonDocument json, int status_code) {
            if (status_code == 200) {
                this.result_old_flow = LoginFlowV2;

                var data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
                var gs = data.value ("globalscale");
                if (gs != QJsonValue.Undefined) {
                    var flow = gs.to_object ().value ("desktoplogin");
                    if (flow != QJsonValue.Undefined) {
                        if (flow.to_int () == 1) {
    #ifdef WITH_WEBENGINE
                            this.result_old_flow = WebViewFlow;
    #else // WITH_WEBENGINE
                            GLib.warn (lc_determine_auth_type_job) << "Server does only support flow1, but this client was compiled without support for flow1";
    #endif // WITH_WEBENGINE
                        }
                    }
                }
            } else {
                this.result_old_flow = Basic;
            }
            this.old_flow_done = true;
            check_all_done ();
        });

        old_flow_required.on_start ();
    }

    void DetermineAuthTypeJob.check_all_done () {
        // Do not conitunue until eve
        if (!this.get_done || !this.propfind_done || !this.old_flow_done) {
            return;
        }

        Q_ASSERT (this.result_get != NoAuthType);
        Q_ASSERT (this.result_propfind != NoAuthType);
        Q_ASSERT (this.result_old_flow != NoAuthType);

        var result = this.result_propfind;

    #ifdef WITH_WEBENGINE
        // WebViewFlow > OAuth > Basic
        if (this.account.server_version_int () >= Account.make_server_version (12, 0, 0)) {
            result = WebViewFlow;
        }
    #endif // WITH_WEBENGINE

        // LoginFlowV2 > WebViewFlow > OAuth > Basic
        if (this.account.server_version_int () >= Account.make_server_version (16, 0, 0)) {
            result = LoginFlowV2;
        }

    #ifdef WITH_WEBENGINE
        // If we determined that we need the webview flow (GS for example) then we switch to that
        if (this.result_old_flow == WebViewFlow) {
            result = WebViewFlow;
        }
    #endif // WITH_WEBENGINE

        // If we determined that a simple get gave us an authentication required error
        // then the server enforces basic auth and we got no choice but to use this
        if (this.result_get == Basic) {
            result = Basic;
        }

        q_c_info (lc_determine_auth_type_job) << "Auth type for" << this.account.dav_url () << "is" << result;
        /* emit */ auth_type (result);
        delete_later ();
    }
};