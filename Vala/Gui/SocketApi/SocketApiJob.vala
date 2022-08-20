/***********************************************************
@author Dominik Schmidt <dev@dominik-schmidt.de>
@author Klaas Freitag <freitag@owncloud.com>
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class SocketApiJob { //: GLib.Object {

//    protected string job_id;
//    protected unowned SocketListener socket_listener;
//    protected Json.Object arguments;

//    public SocketApiJob (string job_id, unowned SocketListener  socket_listener, Json.Object arguments) {
//        this.job_id = job_id;
//        this.socket_listener = socket_listener;
//        this.arguments = arguments;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void resolve (string response = "") {
//        this.socket_listener.on_signal_send_message ("RESOLVE|" + this.job_id + '|' + response);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void resolve (Json.Object response) {
//        resolve (GLib.JsonDocument {
//            response
//        }.to_json ());
//    }


//    /***********************************************************
//    ***********************************************************/
//    public Json.Object arguments () {
//        return this.arguments;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void reject (string response) {
//        this.socket_listener.on_signal_send_message ("REJECT|" + this.job_id + '|' + response);
//    }

} // class SocketApiJob

} // namespace Ui
} // namespace Occ
