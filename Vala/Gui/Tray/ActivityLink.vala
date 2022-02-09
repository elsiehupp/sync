/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtCore>
//  #include <QIcon>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ActivityLink class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/
class ActivityLink {

    /***********************************************************
    ***********************************************************/
    public string label;
    public string link;
    public GLib.ByteArray verb;
    public bool primary;

} // class ActivityLink

} // namespace Ui
} // namespace Occ