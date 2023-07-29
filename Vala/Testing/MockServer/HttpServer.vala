/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv??? or later
***********************************************************/
/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv??? or later
***********************************************************/

//  #include <GLib.TcpServer>

namespace Occ {
namespace Testing {

public class HttpServer { //: GLib.TcpServer {

    /***********************************************************
    ***********************************************************/
    public HttpServer (int16 port) {
        //  base ();
        //  listen (GLib.HostAddress.Any, port);
    }


    /***********************************************************
    ***********************************************************/
    public void incoming_connection (int socket) {
        //  if (disabled)
        //      return;
        //  GLib.Socket tcp_socket = new GLib.Socket (this);
        //  tcp_socket.signal_ready_read.connect (
        //      this.on_signal_read_client
        //  );
        //  tcp_socket.disconnected.connect (
        //      this.on_signal_discard_client
        //  );
        //  tcp_socket.set_socket_descriptor (socket);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client () {
        //  GLib.Socket socket = (GLib.Socket)sender ();
        //  if (socket.can_read_line ()) {
        //      GLib.List<string> tokens = socket.read_line ().split (GLib.Regex ("[ \r\n][ \r\n]*"));
        //      if (tokens[0] == "GET") {
        //          GLib.OutputStream os = new GLib.OutputStream (socket);
        //          os.set_auto_detect_unicode (true);
        //          os += "HTTP/1.0 200 Ok\r\n"
        //              + "Content-Type : text/html; charset=\"utf-8\"\r\n"
        //              + "\r\n"
        //              + "<h1>Nothing to see here</h1>\n"
        //              + GLib.DateTime.current_date_time_utc ().to_string ("\n");
        //          socket.close ();

        //          QtServiceBase.instance.log_message ("Wrote to client");

        //          if (socket.state == GLib.Socket.UnconnectedState) {
        //              delete socket;
        //              QtServiceBase.instance.log_message ("Connection closed");
        //          }
        //      }
        //  }
    }


    private void on_signal_discard_client () {
        //  GLib.Socket socket = (GLib.Socket) sender ();
        //  socket.delete_later ();

        //  QtServiceBase.instance.log_message ("Connection closed");
    }

}

} // namespace Testing
} // namespace Occ
