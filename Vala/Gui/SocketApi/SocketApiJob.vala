/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class Socket_api_job : GLib.Object {

    public Socket_api_job (string job_id, unowned<Socket_listener> socket_listener, QJsonObject arguments)
        : this.job_id (job_id)
        , this.socket_listener (socket_listener)
        , this.arguments (arguments) {
    }

    public void resolve (string response = "");

    public void resolve (QJsonObject response);

    public const QJsonObject arguments () {
        return this.arguments;
    }

    public void reject (string response);

    protected string this.job_id;
    protected unowned<Socket_listener> this.socket_listener;
    protected QJsonObject this.arguments;
}




void Socket_api_job.resolve (string response) {
    this.socket_listener.on_send_message ("RESOLVE|" + this.job_id + '|' + response);
}

void Socket_api_job.resolve (QJsonObject response) {
    resolve (QJsonDocument {
        response
    }.to_json ());
}

void Socket_api_job.reject (string response) {
    this.socket_listener.on_send_message ("REJECT|" + this.job_id + '|' + response);
}
