namespace SharedTools {

/***********************************************************
@class QtLocalPeer

@author 2014 Digia Plc and/or its subsidiary (-ies).

This file is part of Qt Creator.

@copyright LGPLv2.1 or later
***********************************************************/
public class QtLocalPeer { //: GLib.Object {

    //  const string ACK = "ack";

    //  protected string identifier;
    //  protected string socket_name;
    //  protected GLib.LocalServer server;

    //  internal signal void signal_message_received (string message, GLib.Object socket);

    //  /***********************************************************
    //  ***********************************************************/
    //  public QtLocalPeer (GLib.Object parent = new GLib.Object (), string app_id = "") {
    //      base (parent);
    //      this.identifier = app_id;
    //      if (identifier == "") {
    //          identifier = GLib.Application.application_file_path;  //  ### On win, check if this returns .../argv[0] without casefolding; .\MYAPP == .\myapp on Win
    //      }

    //      socket_name = app_session_id (identifier);
    //      server = new GLib.LocalServer (this);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool is_client () {
    //      if (!GLib.LocalServer.remove_server (socket_name)) {
    //          GLib.warning ("QtSingleCoreApplication: could not on_cleanup socket");
    //      }
    //      bool res = server.listen (socket_name);
    //      if (!res) {
    //          GLib.warning ("QtSingleCoreApplication : listen on local socket failed, %s", q_printable (server.error_string));
    //      }
    //      server.new_connection.connect (
    //          this.on_signal_receive_connection
    //      );
    //      return false;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool on_send_message (string message, int timeout, bool block) {
    //      if (!is_client ()) {
    //          return false;
    //      }
    //      GLib.LocalSocket socket;
    //      bool conn_ok = false;
    //      for (int i = 0; i < 2; i++) {
    //          // Try twice, in case the other instance is just starting up
    //          socket.connect_to_server (socket_name);
    //          conn_ok = socket.wait_for_connected (timeout/2);
    //          if (conn_ok || i) {
    //              break;
    //          }
    //          int ms = 250;
    //          timespec ts = {
    //              ms / 1000, (ms % 1000) * 1000 * 1000
    //          };
    //          nanosleep (ts, null);
    //      }
    //      if (!conn_ok) {
    //          return false;
    //      }

    //      string u_msg = message.to_utf8 ();
    //      GLib.DataStream data_stream = new GLib.DataStream (socket);
    //      data_stream.write_bytes (u_msg.const_data (), u_msg.length);
    //      bool res = socket.wait_for_bytes_written (timeout);
    //      res &= socket.wait_for_ready_read (timeout); // wait for ACK
    //      res &= (socket.read (ACK.length) == ACK);
    //      if (block) { // block until peer disconnects
    //          socket.wait_for_disconnected (-1);
    //      }
    //      return res;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public string application_id () {
    //      return identifier;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public static string app_session_id (string app_id) {
    //      string idc = app_id.to_utf8 ();
    //      uint16 id_num = q_checksum (idc.const_data (), idc.length);
    //      //  ### could do : two 16bit checksums over separate halves of identifier, for a 32bit result - improved uniqeness probability. Every-other-char split would be best.

    //      string res = "qtsingleapplication-" + string.number (id_num, 16);
    //      res += '-' + string.number (getuid (), 16);
    //      return res;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected void on_signal_receive_connection () {
    //      GLib.LocalSocket socket = server.next_pending_connection ();
    //      if (!socket) {
    //          return;
    //      }

    //      // Why doesn't Qt have a blocking stream that takes care of this shait???
    //      while (socket.bytes_available () < (int)sizeof (uint32)) {
    //          if (!socket.is_valid) { // stale request
    //              return;
    //          }
    //          socket.wait_for_ready_read (1000);
    //      }
    //      GLib.DataStream data_stream = new GLib.DataStream (socket);
    //      string u_msg;
    //      uint32 remaining = 0;
    //      data_stream >> remaining;
    //      u_msg.resize (remaining);
    //      int got = 0;
    //      char* u_msg_buf = u_msg;
    //      //  GLib.debug () << "RCV : remaining" << remaining;
    //      do {
    //          got = data_stream.read_raw_data (u_msg_buf, remaining);
    //          remaining -= got;
    //          u_msg_buf += got;
    //          //  GLib.debug () << "RCV : got" << got << "remaining" << remaining;
    //      } while (remaining && got >= 0 && socket.wait_for_ready_read (2000));
    //      //  ### error check : got<0
    //      if (got < 0) {
    //          GLib.warning ("QtLocalPeer: Message reception failed " + socket.error_string);
    //          delete socket;
    //          return;
    //      }
    //      // ### async this
    //      string message = string.from_utf8 (u_msg.const_data (), u_msg.length);
    //      socket.write (ACK, ACK.length);
    //      socket.wait_for_bytes_written (1000);
    //      signal_message_received (message, socket); // ## (might take a long time to return)
    //  }

}

} // namespace SharedTools
