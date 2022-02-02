/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class Listener_closure : GLib.Object {

    public using Callback_function = std.function<void ()>;
    public Listener_closure (Callback_function callback)
        : callback_ (callback) {
    }


/***********************************************************
***********************************************************/
public slots:
    void closure_slot () {
        callback_ ();
        delete_later ();
    }


    private Callback_function callback_;
};