/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QtCore>
//  #include <QtCore>
//  #include <Gtk.IconInfo>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The ActivityLink class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/
public class ActivityLink : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public string label;
    public string link;
    public string verb;
    public bool primary;

} // class ActivityLink

} // namespace Ui
} // namespace Occ
