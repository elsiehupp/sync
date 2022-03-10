/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class ListenerClosure : GLib.Object {

    public delegate void CallbackFunction ();

    private CallbackFunction callback;

    public ListenerClosure (CallbackFunction callback) {
        this.callback = callback;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_closure () {
        this.callback ();
        delete_later ();
    }

} // class ListenerClosure

} // namespace Ui
} // namespace Occ
