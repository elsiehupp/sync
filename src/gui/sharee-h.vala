/*
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QFlags>
// #include <QAbstractListModel>
// #include <QLoggingCategory>
// #include <QModelIndex>
// #include <QVariant>
// #include <QSharedPointer>
// #include <QVector>

class QJsonObject;

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcSharing)

class Sharee {
public:
    // Keep in sync with Share.ShareType
    enum Type {
        User = 0,
        Group = 1,
        Email = 4,
        Federated = 6,
        Circle = 7,
        Room = 10
    };

    Sharee (QString shareWith,
        const QString displayName,
        const Type type);

    QString format ();
    QString shareWith ();
    QString displayName ();
    Type type ();

private:
    QString _shareWith;
    QString _displayName;
    Type _type;
};

class ShareeModel : QAbstractListModel {
public:
    enum LookupMode {
        LocalSearch = 0,
        GlobalSearch = 1
    };

    ShareeModel (AccountPtr &account, QString &type, GLib.Object *parent = nullptr);

    using ShareeSet = QVector<QSharedPointer<Sharee>>; // FIXME : make it a QSet<Sharee> when Sharee can be compared
    void fetch (QString &search, ShareeSet &blacklist, LookupMode lookupMode);
    int rowCount (QModelIndex &parent = QModelIndex ()) const override;
    QVariant data (QModelIndex &index, int role) const override;

    QSharedPointer<Sharee> getSharee (int at);

    QString currentSearch () { return _search; }

signals:
    void shareesReady ();
    void displayErrorMessage (int code, QString &);

private slots:
    void shareesFetched (QJsonDocument &reply);

private:
    QSharedPointer<Sharee> parseSharee (QJsonObject &data);
    void setNewSharees (QVector<QSharedPointer<Sharee>> &newSharees);

    AccountPtr _account;
    QString _search;
    QString _type;

    QVector<QSharedPointer<Sharee>> _sharees;
    QVector<QSharedPointer<Sharee>> _shareeBlacklist;
};
}

Q_DECLARE_METATYPE (QSharedPointer<Occ.Sharee>)

#endif //SHAREE_H
