/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtCore>
//  #include <QIcon>

namespace Occ {

/***********************************************************
@brief The Activity_link class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/
class Activity_link {
    // Q_GADGET

    //  Q_PROPERTY (string label MEMBER this.label)
    //  Q_PROPERTY (string link MEMBER this.link)
    //  Q_PROPERTY (GLib.ByteArray verb MEMBER this.verb)
    //  Q_PROPERTY (bool primary MEMBER this.primary)

    /***********************************************************
    ***********************************************************/
    public string this.label;
    public string this.link;
    public GLib.ByteArray this.verb;
    public bool this.primary;
}


}
