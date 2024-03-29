namespace Occ {
namespace Testing {

/***********************************************************
@class FakeWebSocketServer

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class FakeWebSocketServer { //: GLib.Object {


    /***********************************************************
    ***********************************************************/
    private GLib.WebSocketServer web_socket_server;

    /***********************************************************
    ***********************************************************/
    private GLib.SignalSpy process_text_message_spy;

    internal signal void signal_closed ();
    internal signal void signal_process_text_message (GLib.WebSocket sender, string message);

    /***********************************************************
    ***********************************************************/
    public FakeWebSocketServer (uint16 port = 12345) {
        //  base ();
        //  this.web_socket_server = new GLib.WebSocketServer ("Fake Server", GLib.WebSocketServer.NonSecureMode, this);
        //  if (!this.web_socket_server.listen (GLib.HostAddress.Any, port)) {
        //      Q_UNREACHABLE ();
        //  }
        //  this.web_socket_server.new_connection.connect (
        //      this.on_signal_new_connection
        //  );
        //  this.web_socket_server.signal_closed.connect (
        //      this.signal_closed
        //  );
        //  GLib.info ("Open fake websocket server on port: " + port.to_string ());
        //  this.process_text_message_spy = std.make_unique<GLib.SignalSpy> (this, FakeWebSocketServer.signal_process_text_message);
    }

    ~FakeWebSocketServer () {
        //  close ();
    }

    delegate void BeforeAuthentication (PushNotificationManager push_notifications);
    delegate void AfterAuthentication ();

    /***********************************************************
    ***********************************************************/
    public GLib.WebSocket authenticate_account (LibSync.Account account, BeforeAuthentication before_authentication, AfterAuthentication after_authentication) {
        //  var push_notifications = account.push_notifications ();
        //  GLib.assert_true (push_notifications);
        //  GLib.SignalSpy ready_spy = new GLib.SignalSpy (push_notifications, PushNotificationManager.ready);

        //  before_authentication (push_notifications);

        //  // Wait for authentication
        //  if (!wait_for_text_messages ()) {
        //      return null;
        //  }

        //  // Right authentication data should be sent
        //  if (text_messages_count () != 2) {
        //      return null;
        //  }

        //  var socket = socket_for_text_message (0);
        //  var user_sent = text_message (0);
        //  var password_sent = text_message (1);

        //  if (user_sent != account.credentials ().user () || password_sent != account.credentials ().password ()) {
        //      return null;
        //  }

        //  // Sent authenticated
        //  socket.send_text_message ("authenticated");

        //  // Wait for ready signal
        //  ready_spy.wait ();
        //  if (ready_spy.length != 1 || !account.push_notifications ().is_ready ()) {
        //      return null;
        //  }

        //  after_authentication ();

        //  return socket;
    }


    /***********************************************************
    ***********************************************************/
    public void close () {
        //  if (this.web_socket_server.is_listening ()) {
        //      GLib.info ("Close fake websocket server");

        //      this.web_socket_server.close ();
        //      foreach (var client in this.clients) {
        //          delete (client);
        //      }
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public bool wait_for_text_messages () {
        //  return this.process_text_message_spy.wait ();
    }


    /***********************************************************
    ***********************************************************/
    public uint32 text_messages_count () {
        //  return this.process_text_message_spy.length;
    }


    /***********************************************************
    ***********************************************************/
    public string text_message (int message_number) {
        //  GLib.assert_true (0 <= message_number && message_number < this.process_text_message_spy.length);
        //  return this.process_text_message_spy.at (message_number).at (1).to_string ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.WebSocket socket_for_text_message (int message_number) {
        //  GLib.assert_true (0 <= message_number && message_number < this.process_text_message_spy.length);
        //  return this.process_text_message_spy.at (message_number).at (0).value<GLib.WebSocket> ();
    }


    /***********************************************************
    ***********************************************************/
    public void clear_text_messages () {
        //  this.process_text_message_spy = "";
    }


    /***********************************************************
    ***********************************************************/
    public static LibSync.Account create_account (string username = "user", string password = "password") {
        //  var account = LibSync.Account.create ();

        //  GLib.List<string> type_list = new GLib.List<string> ();
        //  type_list.append ("files");
        //  type_list.append ("activities");
        //  type_list.append ("notifications");

        //  string web_socket_url = "ws://localhost:12345";

        //  GLib.HashMap endpoints_map;
        //  endpoints_map["websocket"] = web_socket_url;

        //  GLib.HashMap notify_push_map;
        //  notify_push_map["type"] = type_list;
        //  notify_push_map["endpoints"] = endpoints_map;

        //  GLib.HashMap capabilities_map;
        //  capabilities_map["notify_push"] = notify_push_map;

        //  account.set_capabilities (capabilities_map);

        //  var credentials = new CredentialsStub (username, password);
        //  account.set_credentials (credentials);

        //  return account;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_next_message_internal (string message) {
        //  var client = (GLib.WebSocket) sender ();
        //  signal_process_text_message (client, message);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_connection () {
        //  GLib.info ("New connection on fake websocket server");

        //  var socket = this.web_socket_server.next_pending_connection ();

        //  socket.text_message_received.connect (
        //      this.on_signal_process_next_message_internal
        //  );
        //  socket.disconnected.connect (
        //      this.on_signal_socket_disconnected
        //  );

        //  this.clients + socket;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_socket_disconnected () {
        //  GLib.info ("Socket disconnected");

        //  var client = (GLib.WebSocket) sender ();

        //  if (client) {
        //      this.clients.remove_all (client);
        //      client.delete_later ();
        //  }
    }

} // class FakeWebSocketServer

} // namespace Testing
} // namespace Occ
