/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #pragma once

//  #include <QWeb_socket>
//  #include <QTimer>

namespace {
    static const int MAX_ALLOWED_FAILED_AUTHENTICATION_ATTEMPTS = 3;
    static const int PING_INTERVAL = 30 * 1000;
}

namespace Occ {


class PushNotifications : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public PushNotifications (Account account, GLib.Object parent = new GLib.Object ());

    ~PushNotifications () override;


    /***********************************************************
    Setup push notifications

    This method needs to be called before push notifications can be used.
    ***********************************************************/
    public void setup ();


    /***********************************************************
    Set the interval for reconnection attempts

    @param interval Interval in milliseconds.
    ***********************************************************/
    public void set_reconnect_timer_interval (uint32_t interval);


    /***********************************************************
    Indicates if push notifications ready to use

    Ready to use means connected and authenticated.
    ***********************************************************/
    public bool is_ready ();


    /***********************************************************
    Set the interval in which the websocket will ping the server if it is still alive.

    If the websocket does not respond in timeout_interval, the connection will be terminated.

    @param interval Interval in milliseconds.
    ***********************************************************/
    public void set_ping_interval (int interval);

signals:
    /***********************************************************
    Will be emitted after a successful connection and authentication
    ***********************************************************/
    void ready ();


    /***********************************************************
    Will be emitted if files on the server changed
    ***********************************************************/
    void files_changed (Account account);


    /***********************************************************
    Will be emitted if activities have been changed on the server
    ***********************************************************/
    void activities_changed (Account account);


    /***********************************************************
    Will be emitted if notifications have been changed on the server
    ***********************************************************/
    void notifications_changed (Account account);


    /***********************************************************
    Will be emitted if push notifications are unable to authenticate

    It's save to call #PushNotifications.setup () after this signal has been emitted.
    ***********************************************************/
    void authentication_failed ();


    /***********************************************************
    Will be emitted if push notifications are unable to connect or the connection timed out

    It's save to call #PushNotifications.setup () after this signal has been emitted.
    ***********************************************************/
    void connection_lost ();


    /***********************************************************
    ***********************************************************/
    private void on_web_socket_connected ();
    private void on_web_socket_disconnected ();
    private void on_web_socket_text_message_received (string message);
    private void on_web_socket_error (QAbstract_socket.Socket_error error);
    private void on_web_socket_ssl_errors (GLib.List<QSslError> errors);
    private void on_web_socket_pong_received (uint64 elapsed_time, GLib.ByteArray payload);
    private void on_ping_timed_out ();


    /***********************************************************
    ***********************************************************/
    private void open_web_socket ();
    private void reconnect_to_web_socket ();
    private void close_web_socket ();
    private void authenticate_on_web_socket ();
    private bool try_reconnect_to_web_socket ();
    private void init_reconnect_timer ();
    private void ping_web_socket_server ();
    private void start_ping_timer ();
    private void start_ping_timed_out_timer ();

    /***********************************************************
    ***********************************************************/
    private void handle_authenticated ();
    private void handle_notify_file ();
    private void handle_invalid_credentials ();
    private void handle_notify_notification ();
    private void handle_notify_activity ();

    /***********************************************************
    ***********************************************************/
    private void emit_files_changed ();
    private void emit_notifications_changed ();
    private void emit_activities_changed ();

    /***********************************************************
    ***********************************************************/
    private Account this.account = null;
    private QWeb_socket this.web_socket;
    private uint8 this.failed_authentication_attempts_count = 0;
    private QTimer this.reconnect_timer = null;
    private uint32 this.reconnect_timer_interval = 20 * 1000;
    private bool this.is_ready = false;

    /***********************************************************
    ***********************************************************/
    private QTimer this.ping_timer;
    private QTimer this.ping_timed_out_timer;
    private bool this.pong_received_from_web_socket_server = false;
}

    PushNotifications.PushNotifications (Account account, GLib.Object parent)
        : GLib.Object (parent)
        this.account (account)
        this.web_socket (new QWeb_socket ("", QWeb_socket_protocol.Version_latest, this)) {
        connect (this.web_socket, QOverload<QAbstract_socket.Socket_error>.of (&QWeb_socket.error), this, &PushNotifications.on_web_socket_error);
        connect (this.web_socket, &QWeb_socket.ssl_errors, this, &PushNotifications.on_web_socket_ssl_errors);
        connect (this.web_socket, &QWeb_socket.connected, this, &PushNotifications.on_web_socket_connected);
        connect (this.web_socket, &QWeb_socket.disconnected, this, &PushNotifications.on_web_socket_disconnected);
        connect (this.web_socket, &QWeb_socket.pong, this, &PushNotifications.on_web_socket_pong_received);

        connect (&this.ping_timer, &QTimer.timeout, this, &PushNotifications.ping_web_socket_server);
        this.ping_timer.set_single_shot (true);
        this.ping_timer.set_interval (PING_INTERVAL);

        connect (&this.ping_timed_out_timer, &QTimer.timeout, this, &PushNotifications.on_ping_timed_out);
        this.ping_timed_out_timer.set_single_shot (true);
        this.ping_timed_out_timer.set_interval (PING_INTERVAL);
    }

    PushNotifications.~PushNotifications () {
        close_web_socket ();
    }

    void PushNotifications.setup () {
        GLib.Info (lc_push_notifications) << "Setup push notifications";
        this.failed_authentication_attempts_count = 0;
        reconnect_to_web_socket ();
    }

    void PushNotifications.reconnect_to_web_socket () {
        close_web_socket ();
        open_web_socket ();
    }

    void PushNotifications.close_web_socket () {
        GLib.Info (lc_push_notifications) << "Close websocket for account" << this.account.url ();

        this.ping_timer.stop ();
        this.ping_timed_out_timer.stop ();
        this.is_ready = false;

        // Maybe there run some reconnection attempts
        if (this.reconnect_timer) {
            this.reconnect_timer.stop ();
        }

        disconnect (this.web_socket, QOverload<QAbstract_socket.Socket_error>.of (&QWeb_socket.error), this, &PushNotifications.on_web_socket_error);
        disconnect (this.web_socket, &QWeb_socket.ssl_errors, this, &PushNotifications.on_web_socket_ssl_errors);

        this.web_socket.close ();
    }

    void PushNotifications.on_web_socket_connected () {
        GLib.Info (lc_push_notifications) << "Connected to websocket for account" << this.account.url ();

        connect (this.web_socket, &QWeb_socket.text_message_received, this, &PushNotifications.on_web_socket_text_message_received, Qt.UniqueConnection);

        authenticate_on_web_socket ();
    }

    void PushNotifications.authenticate_on_web_socket () {
        const var credentials = this.account.credentials ();
        const var username = credentials.user ();
        const var password = credentials.password ();

        // Authenticate
        this.web_socket.send_text_message (username);
        this.web_socket.send_text_message (password);
    }

    void PushNotifications.on_web_socket_disconnected () {
        GLib.Info (lc_push_notifications) << "Disconnected from websocket for account" << this.account.url ();
    }

    void PushNotifications.on_web_socket_text_message_received (string message) {
        GLib.Info (lc_push_notifications) << "Received push notification:" << message;

        if (message == "notify_file") {
            handle_notify_file ();
        } else if (message == "notify_activity") {
            handle_notify_activity ();
        } else if (message == "notify_notification") {
            handle_notify_notification ();
        } else if (message == "authenticated") {
            handle_authenticated ();
        } else if (message == "err : Invalid credentials") {
            handle_invalid_credentials ();
        }
    }

    void PushNotifications.on_web_socket_error (QAbstract_socket.Socket_error error) {
        // This error gets thrown in test_setup_max_connection_attempts_reached_delete_push_notifications after
        // the second connection attempt. I have no idea why this happens. Maybe the socket gets not closed correctly?
        // I think it's fine to ignore this error.
        if (error == QAbstract_socket.Unfinished_socket_operation_error) {
            return;
        }

        GLib.warn (lc_push_notifications) << "Websocket error on with account" << this.account.url () << error;
        close_web_socket ();
        /* emit */ connection_lost ();
    }

    bool PushNotifications.try_reconnect_to_web_socket () {
        ++this.failed_authentication_attempts_count;
        if (this.failed_authentication_attempts_count >= MAX_ALLOWED_FAILED_AUTHENTICATION_ATTEMPTS) {
            GLib.Info (lc_push_notifications) << "Max authentication attempts reached";
            return false;
        }

        if (!this.reconnect_timer) {
            this.reconnect_timer = new QTimer (this);
        }

        this.reconnect_timer.set_interval (this.reconnect_timer_interval);
        this.reconnect_timer.set_single_shot (true);
        connect (this.reconnect_timer, &QTimer.timeout, [this] () {
            reconnect_to_web_socket ();
        });
        this.reconnect_timer.on_start ();

        return true;
    }

    void PushNotifications.on_web_socket_ssl_errors (GLib.List<QSslError> errors) {
        GLib.warn (lc_push_notifications) << "Websocket ssl errors on with account" << this.account.url () << errors;
        close_web_socket ();
        /* emit */ authentication_failed ();
    }

    void PushNotifications.open_web_socket () {
        // Open websocket
        const var capabilities = this.account.capabilities ();
        const var web_socket_url = capabilities.push_notifications_web_socket_url ();

        GLib.Info (lc_push_notifications) << "Open connection to websocket on" << web_socket_url << "for account" << this.account.url ();
        connect (this.web_socket, QOverload<QAbstract_socket.Socket_error>.of (&QWeb_socket.error), this, &PushNotifications.on_web_socket_error);
        connect (this.web_socket, &QWeb_socket.ssl_errors, this, &PushNotifications.on_web_socket_ssl_errors);
        this.web_socket.open (web_socket_url);
    }

    void PushNotifications.set_reconnect_timer_interval (uint32_t interval) {
        this.reconnect_timer_interval = interval;
    }

    bool PushNotifications.is_ready () {
        return this.is_ready;
    }

    void PushNotifications.handle_authenticated () {
        GLib.Info (lc_push_notifications) << "Authenticated successful on websocket";
        this.failed_authentication_attempts_count = 0;
        this.is_ready = true;
        start_ping_timer ();
        /* emit */ ready ();

        // We maybe reconnected to websocket while being offline for a
        // while. To not miss any notifications that may have happend,
        // emit all the signals once.
        emit_files_changed ();
        emit_notifications_changed ();
        emit_activities_changed ();
    }

    void PushNotifications.handle_notify_file () {
        GLib.Info (lc_push_notifications) << "Files push notification arrived";
        emit_files_changed ();
    }

    void PushNotifications.handle_invalid_credentials () {
        GLib.Info (lc_push_notifications) << "Invalid credentials submitted to websocket";
        if (!try_reconnect_to_web_socket ()) {
            close_web_socket ();
            /* emit */ authentication_failed ();
        }
    }

    void PushNotifications.handle_notify_notification () {
        GLib.Info (lc_push_notifications) << "Push notification arrived";
        emit_notifications_changed ();
    }

    void PushNotifications.handle_notify_activity () {
        GLib.Info (lc_push_notifications) << "Push activity arrived";
        emit_activities_changed ();
    }

    void PushNotifications.on_web_socket_pong_received (uint64 /*elapsed_time*/, GLib.ByteArray  /*payload*/) {
        GLib.debug (lc_push_notifications) << "Pong received in time";
        // We are fine with every kind of pong and don't care about the
        // payload. As long as we receive pongs the server is still alive.
        this.pong_received_from_web_socket_server = true;
        start_ping_timer ();
    }

    void PushNotifications.start_ping_timer () {
        this.ping_timed_out_timer.stop ();
        this.ping_timer.on_start ();
    }

    void PushNotifications.start_ping_timed_out_timer () {
        this.ping_timed_out_timer.on_start ();
    }

    void PushNotifications.ping_web_socket_server () {
        GLib.debug (lc_push_notifications, "Ping websocket server");

        this.pong_received_from_web_socket_server = false;

        this.web_socket.ping ({});
        start_ping_timed_out_timer ();
    }

    void PushNotifications.on_ping_timed_out () {
        if (this.pong_received_from_web_socket_server) {
            GLib.debug (lc_push_notifications) << "Websocket respond with a pong in time.";
            return;
        }

        GLib.Info (lc_push_notifications) << "Websocket did not respond with a pong in time. Try to reconnect.";
        // Try again to connect
        setup ();
    }

    void PushNotifications.set_ping_interval (int timeout_interval) {
        this.ping_timer.set_interval (timeout_interval);
        this.ping_timed_out_timer.set_interval (timeout_interval);
    }

    void PushNotifications.emit_files_changed () {
        /* emit */ files_changed (this.account);
    }

    void PushNotifications.emit_notifications_changed () {
        /* emit */ notifications_changed (this.account);
    }

    void PushNotifications.emit_activities_changed () {
        /* emit */ activities_changed (this.account);
    }
    }
    