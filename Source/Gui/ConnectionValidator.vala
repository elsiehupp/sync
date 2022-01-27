/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <QLoggingCategory>
// #include <QNetworkReply>
// #include <QNetworkProxyFactory>
// #include <QXmlStreamReader>

// #include <creds/abstractcredentials.h>

// #include <string[]>
// #include <QVariantMap>
// #include <QNetworkReply>

namespace Occ {

/***********************************************************
This is a job-like class to check that the server is up and
that we are connected. here are two entry points:
on_check_server_and_auth and on_check_authentication.
on_check_authentication is the quick version that only does
the propfind while on_check_server_and_auth is doing the 4
calls.

We cannot use the capabilites call to test the l
https://github.com/owncloud/core/issues/12930

Here follows the state machine

\code{.unparsed}
*--. on_check_server_and_auth  (check status.php)
        Will asynchronously check for system proxy (if using system proxy)
        And then invoke on_check_server_and_auth
        CheckServerJob
        |
        +. on_no_status_found -. X
        |
        +. on_job_timeout -. X
        |
        +. on_status_found --+-. X (if credentials are still missing)
                              |
  +---------------------------+
  |
*-+. on_check_authentication (PROPFIND on root)
        PropfindJob
        |
        +. on_auth_failed -. X
        |
        +. on_auth_success --+-. X (depending if coming from on_check_server_and_auth or not)
                              |
  +---------------------------+
  |
  +. check_server_capabilities --------------v (in parallel)
        JsonApiJob (cloud/capabilities)
        +. on_capabilities_recieved -+
                                      |
    +---------------------------------+
    |
  fetch_user
        Utilizes the UserInfo class to fetch the user and avatar image
  +-----------------------------------+
  |
  +. Client Side Encryption Checks --+ --report_result ()
    \endcode
***********************************************************/


class ConnectionValidator : GLib.Object {

    public ConnectionValidator (AccountStatePtr account_state, GLib.Object *parent = nullptr);

    public enum Status {
        Undefined,
        Connected,
        NotConfigured,
        ServerVersionMismatch, // The server version is too old
        CredentialsNotReady, // Credentials aren't ready
        CredentialsWrong, // AuthenticationRequiredError
        SslError, // SSL handshake error, certificate rejected by user?
        StatusNotFound, // Error retrieving status.php
        ServiceUnavailable, // 503 on authed request
        MaintenanceMode, // maintenance enabled in status.php
        Timeout // actually also used for other errors on the authed request
    };

    // How often should the Application ask this object to check for the connection?
    public enum {
        DefaultCallingIntervalMsec = 62 * 1000
    };


    /// Checks the server and the authentication.
    public void on_check_server_and_auth ();
    public void on_system_proxy_lookup_done (QNetworkProxy &proxy);

    /// Checks authentication only.
    public void on_check_authentication ();

signals:
    void connection_result (ConnectionValidator.Status status, string[] &errors);

protected slots:
    void on_check_server_and_auth ();

    void on_status_found (QUrl url, QJsonObject &info);
    void on_no_status_found (QNetworkReply *reply);
    void on_job_timeout (QUrl url);

    void on_auth_failed (QNetworkReply *reply);
    void on_auth_success ();

    void on_capabilities_recieved (QJsonDocument &);
    void on_user_fetched (UserInfo *user_info);


#ifndef TOKEN_AUTH_ONLY
    private void report_connected ();
#endif
    private void report_result (Status status);
    private void check_server_capabilities ();
    private void fetch_user ();

    /***********************************************************
    Sets the account's server version

    Returns false and reports ServerVersionMismatch for very old servers.
    ***********************************************************/
    private bool set_and_check_server_version (string version);

    private string[] _errors;
    private AccountStatePtr _account_state;
    private AccountPtr _account;
    private bool _is_checking_server_and_auth;
};

    // Make sure the timeout for this job is less than how often we get called
    // This makes sure we get tried often enough without "ConnectionValidator already running"
    static int64 timeout_to_use_msec = q_max (1000, ConnectionValidator.DefaultCallingIntervalMsec - 5 * 1000);

    ConnectionValidator.ConnectionValidator (AccountStatePtr account_state, GLib.Object *parent)
        : GLib.Object (parent)
        , _account_state (account_state)
        , _account (account_state.account ())
        , _is_checking_server_and_auth (false) {
    }

    void ConnectionValidator.on_check_server_and_auth () {
        if (!_account) {
            _errors << tr ("No Nextcloud account configured");
            report_result (NotConfigured);
            return;
        }
        q_c_debug (lc_connection_validator) << "Checking server and authentication";

        _is_checking_server_and_auth = true;

        // Lookup system proxy in a thread https://github.com/owncloud/client/issues/2993
        if (ClientProxy.is_using_system_default ()) {
            q_c_debug (lc_connection_validator) << "Trying to look up system proxy";
            ClientProxy.lookup_system_proxy_async (_account.url (),
                this, SLOT (on_system_proxy_lookup_done (QNetworkProxy)));
        } else {
            // We want to reset the QNAM proxy so that the global proxy settings are used (via ClientProxy settings)
            _account.network_access_manager ().set_proxy (QNetworkProxy (QNetworkProxy.DefaultProxy));
            // use a queued invocation so we're as asynchronous as with the other code path
            QMetaObject.invoke_method (this, "on_check_server_and_auth", Qt.QueuedConnection);
        }
    }

    void ConnectionValidator.on_system_proxy_lookup_done (QNetworkProxy &proxy) {
        if (!_account) {
            q_c_warning (lc_connection_validator) << "Bailing out, Account had been deleted";
            return;
        }

        if (proxy.type () != QNetworkProxy.NoProxy) {
            q_c_info (lc_connection_validator) << "Setting QNAM proxy to be system proxy" << ClientProxy.print_q_network_proxy (proxy);
        } else {
            q_c_info (lc_connection_validator) << "No system proxy set by OS";
        }
        _account.network_access_manager ().set_proxy (proxy);

        on_check_server_and_auth ();
    }

    // The actual check
    void ConnectionValidator.on_check_server_and_auth () {
        auto *check_job = new CheckServerJob (_account, this);
        check_job.on_set_timeout (timeout_to_use_msec);
        check_job.set_ignore_credential_failure (true);
        connect (check_job, &CheckServerJob.instance_found, this, &ConnectionValidator.on_status_found);
        connect (check_job, &CheckServerJob.instance_not_found, this, &ConnectionValidator.on_no_status_found);
        connect (check_job, &CheckServerJob.timeout, this, &ConnectionValidator.on_job_timeout);
        check_job.on_start ();
    }

    void ConnectionValidator.on_status_found (QUrl url, QJsonObject &info) {
        // Newer servers don't disclose any version in status.php anymore
        // https://github.com/owncloud/core/pull/27473/files
        // so this string can be empty.
        string server_version = CheckServerJob.version (info);

        // status.php was found.
        q_c_info (lc_connection_validator) << "** Application : own_cloud found : "
                                      << url << " with version "
                                      << CheckServerJob.version_string (info)
                                      << " (" << server_version << ")";

        // Update server url in case of redirection
        if (_account.url () != url) {
            q_c_info (lc_connection_validator ()) << "status.php was redirected to" << url.to_string ();
            _account.set_url (url);
            _account.wants_account_saved (_account.data ());
        }

        if (!server_version.is_empty () && !set_and_check_server_version (server_version)) {
            return;
        }

        // Check for maintenance mode : Servers send "true", so go through QVariant
        // to parse it correctly.
        if (info["maintenance"].to_variant ().to_bool ()) {
            report_result (MaintenanceMode);
            return;
        }

        // now check the authentication
        QTimer.single_shot (0, this, &ConnectionValidator.on_check_authentication);
    }

    // status.php could not be loaded (network or server issue!).
    void ConnectionValidator.on_no_status_found (QNetworkReply *reply) {
        auto job = qobject_cast<CheckServerJob> (sender ());
        q_c_warning (lc_connection_validator) << reply.error () << job.error_string () << reply.peek (1024);
        if (reply.error () == QNetworkReply.SslHandshakeFailedError) {
            report_result (SslError);
            return;
        }

        if (!_account.credentials ().still_valid (reply)) {
            // Note : Why would this happen on a status.php request?
            _errors.append (tr ("Authentication error : Either username or password are wrong."));
        } else {
            //_errors.append (tr ("Unable to connect to %1").arg (_account.url ().to_string ()));
            _errors.append (job.error_string ());
        }
        report_result (StatusNotFound);
    }

    void ConnectionValidator.on_job_timeout (QUrl url) {
        Q_UNUSED (url);
        //_errors.append (tr ("Unable to connect to %1").arg (url.to_string ()));
        _errors.append (tr ("Timeout"));
        report_result (Timeout);
    }

    void ConnectionValidator.on_check_authentication () {
        AbstractCredentials *creds = _account.credentials ();

        if (!creds.ready ()) {
            report_result (CredentialsNotReady);
            return;
        }

        // simply GET the webdav root, will fail if credentials are wrong.
        // continue in on_auth_check here :-)
        q_c_debug (lc_connection_validator) << "# Check whether authenticated propfind works.";
        auto *job = new PropfindJob (_account, "/", this);
        job.on_set_timeout (timeout_to_use_msec);
        job.set_properties (GLib.List<GLib.ByteArray> () << "getlastmodified");
        connect (job, &PropfindJob.result, this, &ConnectionValidator.on_auth_success);
        connect (job, &PropfindJob.finished_with_error, this, &ConnectionValidator.on_auth_failed);
        job.on_start ();
    }

    void ConnectionValidator.on_auth_failed (QNetworkReply *reply) {
        auto job = qobject_cast<PropfindJob> (sender ());
        Status stat = Timeout;

        if (reply.error () == QNetworkReply.SslHandshakeFailedError) {
            _errors << job.error_string_parsing_body ();
            stat = SslError;

        } else if (reply.error () == QNetworkReply.AuthenticationRequiredError
            || !_account.credentials ().still_valid (reply)) {
            q_c_warning (lc_connection_validator) << "******** Password is wrong!" << reply.error () << job.error_string ();
            _errors << tr ("The provided credentials are not correct");
            stat = CredentialsWrong;

        } else if (reply.error () != QNetworkReply.NoError) {
            _errors << job.error_string_parsing_body ();

            const int http_status =
                reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            if (http_status == 503) {
                _errors.clear ();
                stat = ServiceUnavailable;
            }
        }

        report_result (stat);
    }

    void ConnectionValidator.on_auth_success () {
        _errors.clear ();
        if (!_is_checking_server_and_auth) {
            report_result (Connected);
            return;
        }
        check_server_capabilities ();
    }

    void ConnectionValidator.check_server_capabilities () {
        // The main flow now needs the capabilities
        auto *job = new JsonApiJob (_account, QLatin1String ("ocs/v1.php/cloud/capabilities"), this);
        job.on_set_timeout (timeout_to_use_msec);
        GLib.Object.connect (job, &JsonApiJob.json_received, this, &ConnectionValidator.on_capabilities_recieved);
        job.on_start ();
    }

    void ConnectionValidator.on_capabilities_recieved (QJsonDocument &json) {
        auto caps = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
        q_c_info (lc_connection_validator) << "Server capabilities" << caps;
        _account.set_capabilities (caps.to_variant_map ());

        // New servers also report the version in the capabilities
        string server_version = caps["core"].to_object ()["status"].to_object ()["version"].to_string ();
        if (!server_version.is_empty () && !set_and_check_server_version (server_version)) {
            return;
        }

        // Check for the direct_editing capability
        QUrl direct_editing_uRL = QUrl (caps["files"].to_object ()["direct_editing"].to_object ()["url"].to_string ());
        string direct_editing_e_tag = caps["files"].to_object ()["direct_editing"].to_object ()["etag"].to_string ();
        _account.fetch_direct_editors (direct_editing_uRL, direct_editing_e_tag);

        fetch_user ();
    }

    void ConnectionValidator.fetch_user () {
        auto *user_info = new UserInfo (_account_state.data (), true, true, this);
        GLib.Object.connect (user_info, &UserInfo.fetched_last_info, this, &ConnectionValidator.on_user_fetched);
        user_info.set_active (true);
    }

    bool ConnectionValidator.set_and_check_server_version (string version) {
        q_c_info (lc_connection_validator) << _account.url () << "has server version" << version;
        _account.set_server_version (version);

        // We cannot deal with servers < 7.0.0
        if (_account.server_version_int ()
            && _account.server_version_int () < Account.make_server_version (7, 0, 0)) {
            _errors.append (tr ("The configured server for this client is too old"));
            _errors.append (tr ("Please update to the latest server and restart the client."));
            report_result (ServerVersionMismatch);
            return false;
        }
        // We attempt to work with servers >= 7.0.0 but warn users.
        // Check usages of Account.server_version_unsupported () for details.

    #if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
        // Record that the server supports HTTP/2
        // Actual decision if we should use HTTP/2 is done in AccessManager.create_request
        if (auto job = qobject_cast<AbstractNetworkJob> (sender ())) {
            if (auto reply = job.reply ()) {
                _account.set_http2Supported (
                    reply.attribute (QNetworkRequest.HTTP2WasUsedAttribute).to_bool ());
            }
        }
    #endif
        return true;
    }

    void ConnectionValidator.on_user_fetched (UserInfo *user_info) {
        if (user_info) {
            user_info.set_active (false);
            user_info.delete_later ();
        }

    #ifndef TOKEN_AUTH_ONLY
        connect (_account.e2e (), &ClientSideEncryption.initialization_finished, this, &ConnectionValidator.report_connected);
        _account.e2e ().initialize (_account);
    #else
        report_result (Connected);
    #endif
    }

    #ifndef TOKEN_AUTH_ONLY
    void ConnectionValidator.report_connected () {
        report_result (Connected);
    }
    #endif

    void ConnectionValidator.report_result (Status status) {
        emit connection_result (status, _errors);
        delete_later ();
    }

    } // namespace Occ
    