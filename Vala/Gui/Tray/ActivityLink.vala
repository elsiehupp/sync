/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtCore>
//  #include <Gtk.Icon>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ActivityLink class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/
public class ActivityLink {

    /***********************************************************
    ***********************************************************/
    public string label;
    public string link;
    public string verb;
    public bool primary;

} // class ActivityLink

} // namespace Ui
} // namespace Occ
