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
    Q_GADGET

    Q_PROPERTY (string label MEMBER _label)
    Q_PROPERTY (string link MEMBER _link)
    Q_PROPERTY (GLib.ByteArray verb MEMBER _verb)
    Q_PROPERTY (bool primary MEMBER _primary)

    public string _label;
    public string _link;
    public GLib.ByteArray _verb;
    public bool _primary;
};











/***********************************************************
@brief Activity Structure
@ingroup gui

contains all the information describing a single activity.
***********************************************************/
class Activity {

    public using Identifier = QPair<qlonglong, string>;

    public enum Type {
        Activity_type,
        Notification_type,
        Sync_result_type,
        Sync_file_item_type
    };

    public Type _type;
    public qlonglong _id;
    public string _file_action;
    public string _object_type;
    public string _subject;
    public string _message;
    public string _folder;
    public string _file;
    public QUrl _link;
    public QDateTime _date_time;
    public int64 _expire_at_msecs = -1;
    public string _acc_name;
    public string _icon;

    // Stores information about the error
    int _status;

    QVector<Activity_link> _links;
    /***********************************************************
    @brief Sort operator to sort the list youngest first.
    @param val
    @return
    ***********************************************************/

    Identifier ident ();
};

bool operator== (Activity &rhs, Activity &lhs);
bool operator< (Activity &rhs, Activity &lhs);










/***********************************************************
@brief The Activity_list
@ingroup gui

A GLib.List based list of Activities
***********************************************************/
using Activity_list = GLib.List<Activity>;


bool operator< (Activity &rhs, Activity &lhs) {
    return rhs._date_time > lhs._date_time;
}

bool operator== (Activity &rhs, Activity &lhs) {
    return (rhs._type == lhs._type && rhs._id == lhs._id && rhs._acc_name == lhs._acc_name);
}

Activity.Identifier Activity.ident () {
    return Identifier (_id, _acc_name);
}
}
