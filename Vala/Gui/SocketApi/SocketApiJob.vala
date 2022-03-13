/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

public class SocketApiJob : GLib.Object {

    protected string job_id;
    protected unowned SocketListener socket_listener;
    protected QJsonObject arguments;

    public SocketApiJob (string job_id, unowned SocketListener  socket_listener, QJsonObject arguments) {
        this.job_id = job_id;
        this.socket_listener = socket_listener;
        this.arguments = arguments;
    }


    /***********************************************************
    ***********************************************************/
    public void resolve (string response = "") {
        this.socket_listener.on_signal_send_message ("RESOLVE|" + this.job_id + '|' + response);
    }


    /***********************************************************
    ***********************************************************/
    public void resolve (QJsonObject response) {
        resolve (QJsonDocument {
            response
        }.to_json ());
    }


    /***********************************************************
    ***********************************************************/
    public QJsonObject arguments () {
        return this.arguments;
    }


    /***********************************************************
    ***********************************************************/
    public void reject (string response) {
        this.socket_listener.on_signal_send_message ("REJECT|" + this.job_id + '|' + response);
    }

} // class SocketApiJob

} // namespace Ui
} // namespace Occ
