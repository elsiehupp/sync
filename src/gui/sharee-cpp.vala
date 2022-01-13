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

// #include <QJsonObject>
// #include <QJsonDocument>
// #include <QJsonArray>

namespace Occ {

Q_LOGGING_CATEGORY (lcSharing, "nextcloud.gui.sharing", QtInfoMsg)

Sharee.Sharee (QString shareWith,
    const QString displayName,
    const Type type)
    : _shareWith (shareWith)
    , _displayName (displayName)
    , _type (type) {
}

QString Sharee.format () {
    QString formatted = _displayName;

    if (_type == Type.Group) {
        formatted += QLatin1String (" (group)");
    } else if (_type == Type.Email) {
        formatted += QLatin1String (" (email)");
    } else if (_type == Type.Federated) {
        formatted += QLatin1String (" (remote)");
    } else if (_type == Type.Circle) {
        formatted += QLatin1String (" (circle)");
    } else if (_type == Type.Room) {
        formatted += QLatin1String (" (conversation)");
    }

    return formatted;
}

QString Sharee.shareWith () {
    return _shareWith;
}

QString Sharee.displayName () {
    return _displayName;
}

Sharee.Type Sharee.type () {
    return _type;
}

ShareeModel.ShareeModel (AccountPtr &account, QString &type, GLib.Object *parent)
    : QAbstractListModel (parent)
    , _account (account)
    , _type (type) {
}

void ShareeModel.fetch (QString &search, ShareeSet &blacklist, LookupMode lookupMode) {
    _search = search;
    _shareeBlacklist = blacklist;
    auto *job = new OcsShareeJob (_account);
    connect (job, &OcsShareeJob.shareeJobFinished, this, &ShareeModel.shareesFetched);
    connect (job, &OcsJob.ocsError, this, &ShareeModel.displayErrorMessage);
    job.getSharees (_search, _type, 1, 50, lookupMode == GlobalSearch ? true : false);
}

void ShareeModel.shareesFetched (QJsonDocument &reply) {
    QVector<QSharedPointer<Sharee>> newSharees;
 {
        const QStringList shareeTypes {"users", "groups", "emails", "remotes", "circles", "rooms"};

        const auto appendSharees = [this, &shareeTypes] (QJsonObject &data, QVector<QSharedPointer<Sharee>>& out) {
            for (auto &shareeType : shareeTypes) {
                const auto category = data.value (shareeType).toArray ();
                for (auto &sharee : category) {
                    out.append (parseSharee (sharee.toObject ()));
                }
            }
        };

        appendSharees (reply.object ().value ("ocs").toObject ().value ("data").toObject (), newSharees);
        appendSharees (reply.object ().value ("ocs").toObject ().value ("data").toObject ().value ("exact").toObject (), newSharees);
    }

    // Filter sharees that we have already shared with
    QVector<QSharedPointer<Sharee>> filteredSharees;
    foreach (auto &sharee, newSharees) {
        bool found = false;
        foreach (auto &blacklistSharee, _shareeBlacklist) {
            if (sharee.type () == blacklistSharee.type () && sharee.shareWith () == blacklistSharee.shareWith ()) {
                found = true;
                break;
            }
        }

        if (found == false) {
            filteredSharees.append (sharee);
        }
    }

    setNewSharees (filteredSharees);
    shareesReady ();
}

QSharedPointer<Sharee> ShareeModel.parseSharee (QJsonObject &data) {
    QString displayName = data.value ("label").toString ();
    const QString shareWith = data.value ("value").toObject ().value ("shareWith").toString ();
    Sharee.Type type = (Sharee.Type)data.value ("value").toObject ().value ("shareType").toInt ();
    const QString additionalInfo = data.value ("value").toObject ().value ("shareWithAdditionalInfo").toString ();
    if (!additionalInfo.isEmpty ()) {
        displayName = tr ("%1 (%2)", "sharee (shareWithAdditionalInfo)").arg (displayName, additionalInfo);
    }

    return QSharedPointer<Sharee> (new Sharee (shareWith, displayName, type));
}

// Helper function for setNewSharees   (could be a lambda when we can use them)
static QSharedPointer<Sharee> shareeFromModelIndex (QModelIndex &idx) {
    return idx.data (Qt.UserRole).value<QSharedPointer<Sharee>> ();
}

struct FindShareeHelper {
    const QSharedPointer<Sharee> &sharee;
    bool operator () (QSharedPointer<Sharee> &s2) {
        return s2.format () == sharee.format () && s2.displayName () == sharee.format ();
    }
};

/* Set the new sharee

    Do that while preserving the model index so the selection stays
*/
void ShareeModel.setNewSharees (QVector<QSharedPointer<Sharee>> &newSharees) {
    layoutAboutToBeChanged ();
    const auto persistent = persistentIndexList ();
    QVector<QSharedPointer<Sharee>> oldPersistantSharee;
    oldPersistantSharee.reserve (persistent.size ());

    std.transform (persistent.begin (), persistent.end (), std.back_inserter (oldPersistantSharee),
        shareeFromModelIndex);

    _sharees = newSharees;

    QModelIndexList newPersistant;
    newPersistant.reserve (persistent.size ());
    foreach (QSharedPointer<Sharee> &sharee, oldPersistantSharee) {
        FindShareeHelper helper = { sharee };
        auto it = std.find_if (_sharees.constBegin (), _sharees.constEnd (), helper);
        if (it == _sharees.constEnd ()) {
            newPersistant << QModelIndex ();
        } else {
            newPersistant << index (std.distance (_sharees.constBegin (), it));
        }
    }

    changePersistentIndexList (persistent, newPersistant);
    layoutChanged ();
}

int ShareeModel.rowCount (QModelIndex &) {
    return _sharees.size ();
}

QVariant ShareeModel.data (QModelIndex &index, int role) {
    if (index.row () < 0 || index.row () > _sharees.size ()) {
        return QVariant ();
    }

    const auto &sharee = _sharees.at (index.row ());
    if (role == Qt.DisplayRole) {
        return sharee.format ();

    } else if (role == Qt.EditRole) {
        // This role is used by the completer - it should match
        // the full name and the user name and thus we include both
        // in the output here. But we need to take care this string
        // doesn't leak to the user.
        return QString (sharee.displayName () + " (" + sharee.shareWith () + ")");

    } else if (role == Qt.UserRole) {
        return QVariant.fromValue (sharee);
    }

    return QVariant ();
}

QSharedPointer<Sharee> ShareeModel.getSharee (int at) {
    if (at < 0 || at > _sharees.size ()) {
        return QSharedPointer<Sharee> (nullptr);
    }

    return _sharees.at (at);
}
}
