/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

public class SocketApiJobV2 : GLib.Object {

    private unowned SocketListener this.socket_listener;
    private const GLib.ByteArray this.command;
    private string this.job_id;
    private QJsonObject this.arguments;

    signal void signal_finished ();

    public SocketApiJobV2 (unowned SocketListener socket_listener, GLib.ByteArray command, QJsonObject arguments) {
        this.socket_listener = socket_listener;
        this.command = command;
        this.job_id = arguments["identifier"].to_string ();
        this.arguments = arguments["arguments"].to_object ());
        //  ASSERT (!this.job_id.is_empty ())
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
    public GLib.ByteArray command () {
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
