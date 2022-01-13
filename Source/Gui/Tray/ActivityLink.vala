/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>

// #include <QtCore>
// #include <QIcon>

namespace Occ {
/***********************************************************
@brief The ActivityLink class describes actions of an activity

These are part of notifications which are mapped into activities.
***********************************************************/

class ActivityLink {
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
        ActivityType,
        NotificationType,
        SyncResultType,
        SyncFileItemType
    };

    Type _type;
    qlonglong _id;
    string _fileAction;
    string _objectType;
    string _subject;
    string _message;
    string _folder;
    string _file;
    QUrl _link;
    QDateTime _dateTime;
    int64 _expireAtMsecs = -1;
    string _accName;
    string _icon;

    // Stores information about the error
    int _status;

    QVector<ActivityLink> _links;
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
@brief The ActivityList
@ingroup gui

A QList based list of Activities
***********************************************************/
using ActivityList = QList<Activity>;
}

Q_DECLARE_METATYPE (Occ.Activity.Type)
Q_DECLARE_METATYPE (Occ.ActivityLink)








namespace Occ {

    bool operator< (Activity &rhs, Activity &lhs) {
        return rhs._dateTime > lhs._dateTime;
    }
    
    bool operator== (Activity &rhs, Activity &lhs) {
        return (rhs._type == lhs._type && rhs._id == lhs._id && rhs._accName == lhs._accName);
    }
    
    Activity.Identifier Activity.ident () {
        return Identifier (_id, _accName);
    }
    }
    