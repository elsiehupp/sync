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
    Q_PROPERTY (QByteArray verb MEMBER _verb)
    Q_PROPERTY (bool primary MEMBER _primary)

public:
    string _label;
    string _link;
    QByteArray _verb;
    bool _primary;
};

/* ==================================================================== */
/***********************************************************
@brief Activity Structure
@ingroup gui

contains all the information describing a single activity.
***********************************************************/

class Activity {
public:
    using Identifier = QPair<qlonglong, string>;

    enum Type {
        Activity_type,
        Notification_type,
        Sync_result_type,
        Sync_file_item_type
    };

    Type _type;
    qlonglong _id;
    string _file_action;
    string _object_type;
    string _subject;
    string _message;
    string _folder;
    string _file;
    QUrl _link;
    QDateTime _date_time;
    int64 _expire_at_msecs = -1;
    string _acc_name;
    string _icon;

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

/* ==================================================================== */
/***********************************************************
@brief The Activity_list
@ingroup gui

A QList based list of Activities
***********************************************************/
using Activity_list = QList<Activity>;


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
    