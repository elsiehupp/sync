/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief Activity Structure
@ingroup gui

contains all the information describing a single activity.
***********************************************************/
public class Activity { //: GLib.Object {

    //  /***********************************************************
    //  ***********************************************************/
    //  public class Identifier : Pair<int64, string> { }

    //  /***********************************************************
    //  ***********************************************************/
    //  public enum Type {
    //      ACTIVITY,
    //      NOTIFICATION,
    //      SYNC_RESULT,
    //      SYNC_FILE_ITEM
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public Type type;
    //  public int64 identifier;
    //  public string file_action;
    //  public string object_type;
    //  public string subject;
    //  public string message;
    //  public string folder;
    //  public string file;
    //  public GLib.Uri link;
    //  public GLib.DateTime date_time;
    //  public int64 expire_at_msecs = -1;
    //  public string acc_name;
    //  public string icon;

    //  /***********************************************************
    //  Stores information about the error
    //  ***********************************************************/
    //  int status;

    //  GLib.List<ActivityLink> links;

    //  /***********************************************************
    //  @brief Sort operator to sort the list youngest first.
    //  @param val
    //  @return
    //  ***********************************************************/
    //  public Identifier ident () {
    //      return Identifier (this.identifier, this.acc_name);
    //  }


    //  //  bool operator== (Activity rhs, Activity lhs) {
    //  //      return (rhs.type == lhs.type && rhs.id == lhs.id && rhs.acc_name == lhs.acc_name);
    //  //  }


    //  //  bool operator< (Activity rhs, Activity lhs) {
    //  //      return rhs.date_time > lhs.date_time;
    //  //  }

} // class Activity

} // namespace Ui
} // namespace Occ
