/***********************************************************
@author Dominik Schmidt <dev@dominik-schmidt.de>
@author Klaas Freitag <freitag@owncloud.com>
@author Roeland Jago Douma <roeland@famdouma.nl>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class SocketApiJobV2 : GLib.Object {

    private unowned SocketListener this.socket_listener;
    private const string this.command;
    private string this.job_id;
    private QJsonObject this.arguments;

    internal signal void signal_finished ();

    public SocketApiJobV2 (unowned SocketListener socket_listener, string command, QJsonObject arguments) {
        this.socket_listener = socket_listener;
        this.command = command;
        this.job_id = arguments["identifier"].to_string ();
        this.arguments = arguments["arguments"].to_object ());
        //  ASSERT (!this.job_id == "")
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_success (QJsonObject response) {
        do_finish (response);
    }


    /***********************************************************
    ***********************************************************/
    public void failure (string error) {
        do_finish ({
            {
                "error", error
            }
        });
    }


    /***********************************************************
    ***********************************************************/
    public const QJsonObject arguments () {
        return this.arguments;
    }


    /***********************************************************
    ***********************************************************/
    public string command () {
        return this.command;
    }


    /***********************************************************
    ***********************************************************/
    private void do_finish (QJsonObject object) {
        this.socket_listener.on_signal_send_message (this.command + "this.RESULT:" + QJsonDocument ({
            {
                "identifier", this.job_id
            },
            {
                "arguments", object
            }
        }).to_json (QJsonDocument.Compact));
        /* Q_EMIT */ on_signal_finished ();
    }

} // class SocketApiJobV2

} // namespace Ui
} // namespace Occ
