namespace Occ {
namespace LibSync {

/***********************************************************
@class PushNotificationManager

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PushNotificationManager { //: GLib.Object {

    private const int MAX_ALLOWED_FAILED_AUTHENTICATION_ATTEMPTS = 3;
    private const int PING_INTERVAL = 30 * 1000;

    /***********************************************************
    ***********************************************************/
    private Account account = null;
    private GLib.WebSocket web_socket;
    private uint8 failed_authentication_attempts_count = 0;


    private bool reconnect_timer_active = false;

    /***********************************************************
    Set the interval for reconnection attempts

    @param interval Interval in milliseconds.
    ***********************************************************/
    uint32 reconnect_timer_interval { private get; public set; }

    /***********************************************************
    Indicates if push notifications ready to use

    Ready to use means connected and authenticated.
    ***********************************************************/
    public bool is_ready { public get; private set; }

    /***********************************************************
    ***********************************************************/
    private bool ping_timer_active = false;
    private bool ping_timed_out_timer_active = false;

    /***********************************************************
    Set the interval in which the websocket will ping the server if it is still alive.

    If the websocket does not respond in timeout_interval, the connection will be terminated.

    Used by both ping timer and pinged-out timer.

    @param interval Interval in milliseconds.
    ***********************************************************/
    public uint ping_interval { private get; public set; }

    private bool pong_received_from_web_socket_server = false;

    /***********************************************************
    Eitted after a successful connection and authentication
    ***********************************************************/
    internal signal void signal_ready ();

    /***********************************************************
    Emitted when files on the server changed
    ***********************************************************/
    internal signal void signal_files_changed (Account account);

    /***********************************************************
    Emitted when activities have been changed on the server
    ***********************************************************/
    internal signal void signal_activities_changed (Account account);

    /***********************************************************
    Emitted when notifications have been changed on the server
    ***********************************************************/
    internal signal void signal_notifications_changed (Account account);

    /***********************************************************
    Emitted when push notifications are unable to authenticate

    It's safe to call PushNotificationManager.up () after this signal
    has been emitted.
    ***********************************************************/
    internal signal void signal_authentication_failed ();

    /***********************************************************
    Emitted when push notifications are unable to connect or the connection timed out

    It's save to call #PushNotificationManager.up () after this signal has been emitted.
    ***********************************************************/
    internal signal void signal_connection_lost ();

    /***********************************************************
    ***********************************************************/
    public PushNotificationManager (Account account) {
        //  base ();
        //  this.account = account;
        //  this.reconnect_timer_interval = 20 * 1000;
        //  this.is_ready = false;
        //  this.web_socket = new GLib.WebSocket ("", GLib.Web_socket_protocol.Version_latest, this);
        //  this.web_socket.error.connect (
        //      this.on_signal_web_socket_error
        //  );
        //  this.web_socket.signal_ssl_errors.connect (
        //      this.on_signal_web_socket_ssl_errors
        //  );
        //  this.web_socket.connected.connect (
        //      this.on_signal_web_socket_connected
        //  );
        //  this.web_socket.disconnected.connect (
        //      this.on_signal_web_socket_disconnected
        //  );
        //  this.web_socket.pong.connect (
        //      this.on_signal_web_socket_pong_received
        //  );
        //  this.start_ping_timer ();
    }


    ~PushNotificationManager () {
        //  close_web_socket ();
    }


    /***********************************************************
    Set up push notifications

    This method needs to be called before push notifications can be used.
    ***********************************************************/
    public void up () {
        //  GLib.info ("Setting up push notifications.");
        //  this.failed_authentication_attempts_count = 0;
        //  reconnect_to_web_socket ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_web_socket_connected () {
        //  GLib.info ("Connected to websocket for account " + this.account.url.to_string ());

        //  this.web_socket.text_message_received.connect (
        //      this.on_signal_web_socket_text_message_received // GLib.UniqueConnection
        //  );

        //  authenticate_on_signal_web_socket ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_web_socket_disconnected () {
        //  GLib.info ("Disconnected from websocket for account " + this.account.url.to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_web_socket_text_message_received (string message) {
        //  GLib.info ("Received push notification: " + message);

        //  if (message == "notify_file") {
        //      handle_notify_file ();
        //  } else if (message == "notify_activity") {
        //      handle_notify_activity ();
        //  } else if (message == "notify_notification") {
        //      handle_notify_notification ();
        //  } else if (message == "authenticated") {
        //      handle_authenticated ();
        //  } else if (message == "err : Invalid credentials") {
        //      handle_invalid_credentials ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_web_socket_error (GLib.AbstractSocket.SocketError error) {
        //  /***********************************************************
        //  This error gets thrown in test_setup_max_connection_attempts_reached_delete_push_notifications
        //  after the second connection attempt. I have no idea why this
        //  happens. Maybe the socket gets not closed correctly? I think
        //  it's fine to ignore this error.
        //  ***********************************************************/
        //  if (error == GLib.AbstractSocket.UnfinishedSocketOperationError) {
        //      return;
        //  }

        //  GLib.warning ("Websocket error on with account " + this.account.url.to_string () + error.to_string ());
        //  close_web_socket ();
        //  signal_connection_lost ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_web_socket_ssl_errors (GLib.List<GnuTLS.ErrorCode> errors) {
        //  GLib.warning ("Websocket ssl errors with account " + this.account.url.to_string () + errors.to_string ());
        //  close_web_socket ();
        //  signal_authentication_failed ();
    }


    /***********************************************************
    We are fine with every kind of pong and don't care about the
    payload. As long as we receive pongs the server is still alive.
    ***********************************************************/
    private void on_signal_web_socket_pong_received (uint64 elapsed_time, string payload) {
        //  GLib.debug ("Pong received in time.");
        //  this.pong_received_from_web_socket_server = true;
        //  start_ping_timer ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_ping_timed_out_timer_timed_out () {
        //  if (this.pong_received_from_web_socket_server) {
        //      GLib.debug ("Websocket respond with a pong in time.");
        //      return false; // only run once
        //  }

        //  GLib.info ("Websocket did not respond with a pong in time. Try to reconnect.");
        //  // Try again to connect
        //  up ();
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    private void open_web_socket () {
        //  // Open websocket
        //  var capabilities = this.account.capabilities;
        //  string web_socket_url = capabilities.push_notifications_web_socket_url ();

        //  GLib.info ("Open connection to websocket on " + web_socket_url + " for account " + this.account.url);
        //  this.web_socket.error.connect (
        //      this.on_signal_web_socket_error
        //  );
        //  this.web_socket.signal_ssl_errors.connect (
        //      this.on_signal_web_socket_ssl_errors
        //  );
        //  this.web_socket.open (web_socket_url);
    }


    /***********************************************************
    ***********************************************************/
    private void reconnect_to_web_socket () {
        //  close_web_socket ();
        //  open_web_socket ();
    }


    /***********************************************************
    ***********************************************************/
    private void close_web_socket () {
        //  GLib.info ("Closing websocket for account " + this.account.url.to_string ());

        //  this.ping_timer_active = false;
        //  this.ping_timed_out_timer_active = false;
        //  this.is_ready = false;

        //  // Maybe there run some reconnection attempts
        //  if (this.reconnect_timer_active) {
        //      this.reconnect_timer_active = false;
        //  }

        //  disconnect (this.web_socket, GLib.Overload<GLib.AbstractSocket.SocketError>.of (GLib.WebSocket.error), this, PushNotificationManager.on_signal_web_socket_error);
        //  disconnect (this.web_socket, GLib.WebSocket.signal_ssl_errors, this, PushNotificationManager.on_signal_web_socket_ssl_errors);

        //  this.web_socket.close ();
    }


    /***********************************************************
    ***********************************************************/
    private void authenticate_on_signal_web_socket () {
        //  var credentials = this.account.credentials;
        //  var username = credentials.user;
        //  var password = credentials.password;

        //  // Authenticate
        //  this.web_socket.send_text_message (username);
        //  this.web_socket.send_text_message (password);
    }


    /***********************************************************
    ***********************************************************/
    private bool try_reconnect_to_web_socket () {
        //  this.failed_authentication_attempts_count++;
        //  if (this.failed_authentication_attempts_count >= MAX_ALLOWED_FAILED_AUTHENTICATION_ATTEMPTS) {
        //      GLib.info ("Max authentication attempts reached.");
        //      return false;
        //  }
        //  this.reconnect_timer_active = true;
        //  GLib.Timeout.add (
        //      this.reconnect_timer_interval,
        //      this.on_reconnnect_timer_finished
        //  );
        //  return true;
    }


    private bool on_reconnnect_timer_finished () {
        //  if (this.reconnect_timer_active) {
        //      this.reconnect_to_web_socket ();
        //  }
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_ping_timer_timeout () {
        //  this.pong_received_from_web_socket_server = false;
        //  this.web_socket.ping ({});
        //  start_ping_timed_out_timer ();
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    private void start_ping_timer () {
        //  this.ping_timed_out_timer_active = false;
        //  this.ping_timer_active = true;
        //  GLib.Timeout.add (
        //      PING_INTERVAL,
        //      this.on_signal_ping_timer_timeout
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void start_ping_timed_out_timer () {
        //  this.ping_timed_out_timer_active = true;
        //  GLib.Timeout.add (
        //      PING_INTERVAL,
        //      this.on_signal_ping_timed_out_timer_timed_out
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void handle_authenticated () {
        //  GLib.info ("Authenticated successfully on websocket.");
        //  this.failed_authentication_attempts_count = 0;
        //  this.is_ready = true;
        //  start_ping_timer ();
        //  signal_ready ();

        //  // We maybe reconnected to websocket while being offline for a
        //  // while. To not miss any notifications that may have happend,
        //  // emit all the signals once.
        //  signal_files_changed (this.account);
        //  signal_notifications_changed (this.account);
        //  signal_activities_changed (this.account);
    }


    /***********************************************************
    ***********************************************************/
    private void handle_notify_file () {
        //  GLib.info ("Files push notification arrived.");
        //  signal_files_changed (this.account);
    }


    /***********************************************************
    ***********************************************************/
    private void handle_invalid_credentials () {
        //  GLib.info ("Invalid credentials submitted to websocket.");
        //  if (!try_reconnect_to_web_socket ()) {
        //      close_web_socket ();
        //      signal_authentication_failed ();
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void handle_notify_notification () {
        //  GLib.info ("Push notification arrived.");
        //  signal_notifications_changed (this.account);
    }


    /***********************************************************
    ***********************************************************/
    private void handle_notify_activity () {
        //  GLib.info ("Push activity arrived.");
        //  signal_activities_changed (this.account);
    }

} // class PushNotificationManager

} // namespace LibSync
} // namespace Occ
    