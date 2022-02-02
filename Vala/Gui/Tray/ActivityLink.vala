/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>

// #include <QtCore>
// #include <QIcon>

namespace Occ {










/***********************************************************
@brief The Activity_link class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/
class Activity_link {
    // Q_GADGET

    Q_PROPERTY (string label MEMBER this.label)
    Q_PROPERTY (string link MEMBER this.link)
    Q_PROPERTY (GLib.ByteArray verb MEMBER this.verb)
    Q_PROPERTY (bool primary MEMBER this.primary)

    /***********************************************************
    ***********************************************************/
    public string this.label;
    public string this.link;
    public GLib.ByteArray this.verb;
    public bool this.primary;
};











/***********************************************************
@brief Activity Structure
@ingroup gui

contains all the information describing a single activity.
***********************************************************/
class Activity {

    /***********************************************************
    ***********************************************************/
    public using Identifier = QPair<qlonglong, string>;

    /***********************************************************
    ***********************************************************/
    public enum Type {
        Activity_type,
        Notification_type,
        Sync_result_type,
        Sync_file_item_type
    };

    /***********************************************************
    ***********************************************************/
    public Type this.type;
    public qlonglong this.id;
    public string this.file_action;
    public string this.object_type;
    public string this.subject;
    public string this.message;
    public string this.folder;
    public string this.file;
    public GLib.Uri this.link;
    public GLib.DateTime this.date_time;
    public int64 this.expire_at_msecs = -1;
    public string this.acc_name;
    public string this.icon;

    // Stores information about the error
    int this.status;

    GLib.Vector<Activity_link> this.links;
    /***********************************************************
    @brief Sort operator to sort the list youngest first.
    @param val
    @return
    ***********************************************************/

    Identifier ident ();
};

bool operator== (Activity rhs, Activity lhs);
bool operator< (Activity rhs, Activity lhs);










/***********************************************************
@brief The Activity_list
@ingroup gui

A GLib.List based list of Activities
***********************************************************/
using Activity_list = GLib.List<Activity>;


bool operator< (Activity rhs, Activity lhs) {
    return rhs._date_time > lhs._date_time;
}

bool operator== (Activity rhs, Activity lhs) {
    return (rhs._type == lhs._type && rhs._id == lhs._id && rhs._acc_name == lhs._acc_name);
}

Activity.Identifier Activity.ident () {
    return Identifier (this.id, this.acc_name);
}
}
