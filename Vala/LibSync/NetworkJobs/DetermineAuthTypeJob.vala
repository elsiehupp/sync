/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Checks with auth type to use for a server
@ingroup libsync
***********************************************************/
class DetermineAuthTypeJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum AuthType {
        /***********************************************************
        Used only before we got a chance to probe the server
        ***********************************************************/
        NO_AUTH_TYPE,
    
        /***********************************************************
        ***********************************************************/
#ifdef WITH_WEBENGINE
        WEB_VIEW_FLOW,
#endif // WITH_WEBENGINE

        /***********************************************************
        Also the catch-all fallback for backwards compatibility
        reasons
        ***********************************************************/
        BASIC,

        /***********************************************************
        ***********************************************************/
        OAUTH,

        /***********************************************************
        ***********************************************************/
        LOGIN_FLOW_V2
    }


    /***********************************************************
    ***********************************************************/
    private AccountPointer account;
    private AuthType result_get = AuthType.NO_AUTH_TYPE;
    private AuthType result_propfind = AuthType.NO_AUTH_TYPE;
    private AuthType result_old_flow = AuthType.NO_AUTH_TYPE;
    private bool get_done = false;
    private bool propfind_done = false;
    private bool old_flow_done = false;


    signal void auth_type (AuthType);


    /***********************************************************
    ***********************************************************/
    public DetermineAuthTypeJob (AccountPointer account, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        GLib.Info (lc_determine_auth_type_job) << "Determining auth type for" << this.account.dav_url ();

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
                            this.result_old_flow = WEB_VIEW_FLOW;
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


    /***********************************************************
    ***********************************************************/
    private void check_all_done () {
        // Do not conitunue until eve
        if (!this.get_done || !this.propfind_done || !this.old_flow_done) {
            return;
        }

        //  Q_ASSERT (this.result_get != NO_AUTH_TYPE);
        //  Q_ASSERT (this.result_propfind != NO_AUTH_TYPE);
        //  Q_ASSERT (this.result_old_flow != NO_AUTH_TYPE);

        var result = this.result_propfind;

    #ifdef WITH_WEBENGINE
        // WEB_VIEW_FLOW > OAuth > Basic
        if (this.account.server_version_int () >= Account.make_server_version (12, 0, 0)) {
            result = WEB_VIEW_FLOW;
        }
    #endif // WITH_WEBENGINE

        // LoginFlowV2 > WEB_VIEW_FLOW > OAuth > Basic
        if (this.account.server_version_int () >= Account.make_server_version (16, 0, 0)) {
            result = LoginFlowV2;
        }

    #ifdef WITH_WEBENGINE
        // If we determined that we need the webview flow (GS for example) then we switch to that
        if (this.result_old_flow == WEB_VIEW_FLOW) {
            result = WEB_VIEW_FLOW;
        }
    #endif // WITH_WEBENGINE

        // If we determined that a simple get gave us an authentication required error
        // then the server enforces basic auth and we got no choice but to use this
        if (this.result_get == Basic) {
            result = Basic;
        }

        GLib.Info (lc_determine_auth_type_job) << "Auth type for" << this.account.dav_url () << "is" << result;
        /* emit */ auth_type (result);
        delete_later ();
    }

} // class DetermineAuthTypeJob

} // namespace Occ
