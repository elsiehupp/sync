/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class Socket_api_job_v2 : GLib.Object {

    public Socket_api_job_v2 (unowned<Socket_listener> socket_listener, GLib.ByteArray command, QJsonObject arguments);

    public void on_signal_success (QJsonObject response);
    public void failure (string error);

    public const QJsonObject arguments () {
        return this.arguments;
    }
    public GLib.ByteArray command () {
        return this.command;
    }

signals:
    void on_signal_finished ();


    private void do_finish (QJsonObject obj);

    private unowned<Socket_listener> this.socket_listener;
    private const GLib.ByteArray this.command;
    private string this.job_id;
    private QJsonObject this.arguments;
}




Socket_api_job_v2.Socket_api_job_v2 (unowned<Socket_listener> socket_listener, GLib.ByteArray command, QJsonObject arguments)
    : this.socket_listener (socket_listener)
    this.command (command)
    this.job_id (arguments["identifier"].to_string ())
    this.arguments (arguments["arguments"].to_object ()) {
    //  ASSERT (!this.job_id.is_empty ())
}

void Socket_api_job_v2.on_signal_success (QJsonObject response) {
    do_finish (response);
}

void Socket_api_job_v2.failure (string error) {
    do_finish ({
        {
            "error", error
        }
    });
}

void Socket_api_job_v2.do_finish (QJsonObject obj) {
    this.socket_listener.on_signal_send_message (this.command + "this.RESULT:" + QJsonDocument ({
        {
            "identifier", this.job_id
        },
        {
            "arguments", obj
        }
    }).to_json (QJsonDocument.Compact));
    /* Q_EMIT */ on_signal_finished ();
}