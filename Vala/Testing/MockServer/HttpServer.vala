/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTcpServer>

namespace Occ {
namespace Testing {

public class HttpServer : QTcpServer {

    /***********************************************************
    ***********************************************************/
    public HttpServer (int16 port, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        listen (QHostAddress.Any, port);
    }


    /***********************************************************
    ***********************************************************/
    public void incoming_connection (int socket) {
        if (disabled)
            return;
        QTcpSocket tcp_socket = new QTcpSocket (this);
        tcp_socket.signal_ready_read.connect (
            this.on_signal_read_client
        );
        tcp_socket.disconnected.connect (
            this.on_signal_discard_client
        );
        tcp_socket.set_socket_descriptor (socket);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client () {
        QTcpSocket* socket = (QTcpSocket*)sender ();
        if (socket.can_read_line ()) {
            string[] tokens = socket.read_line ().split (QRegularExpression ("[ \r\n][ \r\n]*"));
            if (tokens[0] == "GET") {
                QTextStream os = new QTextStream (socket);
                os.set_auto_detect_unicode (true);
                os += "HTTP/1.0 200 Ok\r\n"
                    + "Content-Type : text/html; charset=\"utf-8\"\r\n"
                    + "\r\n"
                    + "<h1>Nothing to see here</h1>\n"
                    + GLib.DateTime.current_date_time_utc ().to_string ("\n");
                socket.close ();

                QtServiceBase.instance.log_message ("Wrote to client");

                if (socket.state == QTcpSocket.UnconnectedState) {
                    delete socket;
                    QtServiceBase.instance.log_message ("Connection closed");
                }
            }
        }
    }


    private void on_signal_discard_client () {
        QTcpSocket socket = (QTcpSocket) sender ();
        socket.delete_later ();

        QtServiceBase.instance.log_message ("Connection closed");
    }

}

} // namespace Testing
} // namespace Occ
