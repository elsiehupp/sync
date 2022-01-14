/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonObject>
// #include <QJsonDocument>
// #include <QJsonArray>

// #include <GLib.Object>
// #include <QFlags>
// #include <QAbstractListModel>
// #include <QLoggingCategory>
// #include <QModelIndex>
// #include <QVariant>
// #include <QSharedPointer>
// #include <QVector>

namespace Occ {



class Sharee {

    // Keep in sync with Share.Share_type
    public enum Type {
        User = 0,
        Group = 1,
        Email = 4,
        Federated = 6,
        Circle = 7,
        Room = 10
    };

    public Sharee (string share_with,
        const string display_name,
        const Type type);

    public string format ();
    public string share_with ();
    public string display_name ();
    public Type type ();

private:
    string _share_with;
    string _display_name;
    Type _type;
};

class Sharee_model : QAbstractListModel {

    public enum Lookup_mode {
        Local_search = 0,
        Global_search = 1
    };

    public Sharee_model (AccountPtr &account, string &type, GLib.Object *parent = nullptr);

    public using Sharee_set = QVector<QSharedPointer<Sharee>>; // FIXME : make it a QSet<Sharee> when Sharee can be compared
    public void fetch (string &search, Sharee_set &blacklist, Lookup_mode lookup_mode);
    public int row_count (QModelIndex &parent = QModelIndex ()) const override;
    public QVariant data (QModelIndex &index, int role) const override;

    public QSharedPointer<Sharee> get_sharee (int at);

    public string current_search () {
        return _search;
    }

signals:
    void sharees_ready ();
    void display_error_message (int code, string &);

private slots:
    void sharees_fetched (QJsonDocument &reply);

private:
    QSharedPointer<Sharee> parse_sharee (QJsonObject &data);
    void set_new_sharees (QVector<QSharedPointer<Sharee>> &new_sharees);

    AccountPtr _account;
    string _search;
    string _type;

    QVector<QSharedPointer<Sharee>> _sharees;
    QVector<QSharedPointer<Sharee>> _sharee_blacklist;
};

    Sharee.Sharee (string share_with,
        const string display_name,
        const Type type)
        : _share_with (share_with)
        , _display_name (display_name)
        , _type (type) {
    }

    string Sharee.format () {
        string formatted = _display_name;

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

    string Sharee.share_with () {
        return _share_with;
    }

    string Sharee.display_name () {
        return _display_name;
    }

    Sharee.Type Sharee.type () {
        return _type;
    }

    Sharee_model.Sharee_model (AccountPtr &account, string &type, GLib.Object *parent)
        : QAbstractListModel (parent)
        , _account (account)
        , _type (type) {
    }

    void Sharee_model.fetch (string &search, Sharee_set &blacklist, Lookup_mode lookup_mode) {
        _search = search;
        _sharee_blacklist = blacklist;
        auto *job = new Ocs_sharee_job (_account);
        connect (job, &Ocs_sharee_job.sharee_job_finished, this, &Sharee_model.sharees_fetched);
        connect (job, &Ocs_job.ocs_error, this, &Sharee_model.display_error_message);
        job.get_sharees (_search, _type, 1, 50, lookup_mode == Global_search ? true : false);
    }

    void Sharee_model.sharees_fetched (QJsonDocument &reply) {
        QVector<QSharedPointer<Sharee>> new_sharees;
     {
            const QStringList sharee_types {"users", "groups", "emails", "remotes", "circles", "rooms"};

            const auto append_sharees = [this, &sharee_types] (QJsonObject &data, QVector<QSharedPointer<Sharee>>& out) {
                for (auto &sharee_type : sharee_types) {
                    const auto category = data.value (sharee_type).to_array ();
                    for (auto &sharee : category) {
                        out.append (parse_sharee (sharee.to_object ()));
                    }
                }
            };

            append_sharees (reply.object ().value ("ocs").to_object ().value ("data").to_object (), new_sharees);
            append_sharees (reply.object ().value ("ocs").to_object ().value ("data").to_object ().value ("exact").to_object (), new_sharees);
        }

        // Filter sharees that we have already shared with
        QVector<QSharedPointer<Sharee>> filtered_sharees;
        foreach (auto &sharee, new_sharees) {
            bool found = false;
            foreach (auto &blacklist_sharee, _sharee_blacklist) {
                if (sharee.type () == blacklist_sharee.type () && sharee.share_with () == blacklist_sharee.share_with ()) {
                    found = true;
                    break;
                }
            }

            if (found == false) {
                filtered_sharees.append (sharee);
            }
        }

        set_new_sharees (filtered_sharees);
        sharees_ready ();
    }

    QSharedPointer<Sharee> Sharee_model.parse_sharee (QJsonObject &data) {
        string display_name = data.value ("label").to_string ();
        const string share_with = data.value ("value").to_object ().value ("share_with").to_string ();
        Sharee.Type type = (Sharee.Type)data.value ("value").to_object ().value ("share_type").to_int ();
        const string additional_info = data.value ("value").to_object ().value ("share_with_additional_info").to_string ();
        if (!additional_info.is_empty ()) {
            display_name = tr ("%1 (%2)", "sharee (share_with_additional_info)").arg (display_name, additional_info);
        }

        return QSharedPointer<Sharee> (new Sharee (share_with, display_name, type));
    }

    // Helper function for set_new_sharees   (could be a lambda when we can use them)
    static QSharedPointer<Sharee> sharee_from_model_index (QModelIndex &idx) {
        return idx.data (Qt.User_role).value<QSharedPointer<Sharee>> ();
    }

    struct Find_sharee_helper {
        const QSharedPointer<Sharee> &sharee;
        bool operator () (QSharedPointer<Sharee> &s2) {
            return s2.format () == sharee.format () && s2.display_name () == sharee.format ();
        }
    };

    /* Set the new sharee

        Do that while preserving the model index so the selection stays
    ***********************************************************/
    void Sharee_model.set_new_sharees (QVector<QSharedPointer<Sharee>> &new_sharees) {
        layout_about_to_be_changed ();
        const auto persistent = persistent_index_list ();
        QVector<QSharedPointer<Sharee>> old_persistant_sharee;
        old_persistant_sharee.reserve (persistent.size ());

        std.transform (persistent.begin (), persistent.end (), std.back_inserter (old_persistant_sharee),
            sharee_from_model_index);

        _sharees = new_sharees;

        QModel_index_list new_persistant;
        new_persistant.reserve (persistent.size ());
        foreach (QSharedPointer<Sharee> &sharee, old_persistant_sharee) {
            Find_sharee_helper helper = {
                sharee
            };
            auto it = std.find_if (_sharees.const_begin (), _sharees.const_end (), helper);
            if (it == _sharees.const_end ()) {
                new_persistant << QModelIndex ();
            } else {
                new_persistant << index (std.distance (_sharees.const_begin (), it));
            }
        }

        change_persistent_index_list (persistent, new_persistant);
        layout_changed ();
    }

    int Sharee_model.row_count (QModelIndex &) {
        return _sharees.size ();
    }

    QVariant Sharee_model.data (QModelIndex &index, int role) {
        if (index.row () < 0 || index.row () > _sharees.size ()) {
            return QVariant ();
        }

        const auto &sharee = _sharees.at (index.row ());
        if (role == Qt.Display_role) {
            return sharee.format ();

        } else if (role == Qt.Edit_role) {
            // This role is used by the completer - it should match
            // the full name and the user name and thus we include both
            // in the output here. But we need to take care this string
            // doesn't leak to the user.
            return string (sharee.display_name () + " (" + sharee.share_with () + ")");

        } else if (role == Qt.User_role) {
            return QVariant.from_value (sharee);
        }

        return QVariant ();
    }

    QSharedPointer<Sharee> Sharee_model.get_sharee (int at) {
        if (at < 0 || at > _sharees.size ()) {
            return QSharedPointer<Sharee> (nullptr);
        }

        return _sharees.at (at);
    }
    }
    