/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonObject>
// #include <QJsonDocument>
// #include <QJsonArray>

// #include <QFlags>
// #include <QAbstractListModel>
// #include <QLoggingCategory>
// #include <QModelIndex>
// #include <GLib.Variant>

// #include <GLib.Vector>

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

    /***********************************************************
    ***********************************************************/
    public Sharee (string share_with,
        const string display_name,
        const Type type);

    /***********************************************************
    ***********************************************************/
    public string format ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string display_name ();


    public Type type ();


    /***********************************************************
    ***********************************************************/
    private string this.share_with;
    private string this.display_name;
    private Type this.type;
};

class Sharee_model : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public enum Lookup_mode {
        Local_search = 0,
        Global_search = 1
    };

    /***********************************************************
    ***********************************************************/
    public Sharee_model (AccountPointer account, string type, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public using Sharee_set = GLib.Vector<unowned<Sharee>>; // FIXME : make it a GLib.Set<Sharee> when Sharee can be compared
    public void fetch (string search, Sharee_set blocklist, Lookup_mode lookup_mode);


    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex parent = QModelIndex ()) override;

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public string current_search () {
        return this.search;
    }

signals:
    void sharees_ready ();
    void display_error_message (int code, string );


    /***********************************************************
    ***********************************************************/
    private void on_sharees_fetched (QJsonDocument reply);

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private void set_new_sharees (GLib.Vector<unowned<Sharee>> new_sharees);

    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
    private string this.search;
    private string this.type;

    /***********************************************************
    ***********************************************************/
    private GLib.Vector<unowned<Sharee>> this.sharees;
    private GLib.Vector<unowned<Sharee>> this.sharee_blocklist;
};

    Sharee.Sharee (string share_with,
        const string display_name,
        const Type type)
        : this.share_with (share_with)
        , this.display_name (display_name)
        , this.type (type) {
    }

    string Sharee.format () {
        string formatted = this.display_name;

        if (this.type == Type.Group) {
            formatted += QLatin1String (" (group)");
        } else if (this.type == Type.Email) {
            formatted += QLatin1String (" (email)");
        } else if (this.type == Type.Federated) {
            formatted += QLatin1String (" (remote)");
        } else if (this.type == Type.Circle) {
            formatted += QLatin1String (" (circle)");
        } else if (this.type == Type.Room) {
            formatted += QLatin1String (" (conversation)");
        }

        return formatted;
    }

    string Sharee.share_with () {
        return this.share_with;
    }

    string Sharee.display_name () {
        return this.display_name;
    }

    Sharee.Type Sharee.type () {
        return this.type;
    }

    Sharee_model.Sharee_model (AccountPointer account, string type, GLib.Object parent)
        : QAbstractListModel (parent)
        , this.account (account)
        , this.type (type) {
    }

    void Sharee_model.fetch (string search, Sharee_set blocklist, Lookup_mode lookup_mode) {
        this.search = search;
        this.sharee_blocklist = blocklist;
        var job = new Ocs_sharee_job (this.account);
        connect (job, &Ocs_sharee_job.sharee_job_finished, this, &Sharee_model.on_sharees_fetched);
        connect (job, &Ocs_job.ocs_error, this, &Sharee_model.display_error_message);
        job.get_sharees (this.search, this.type, 1, 50, lookup_mode == Global_search ? true : false);
    }

    void Sharee_model.on_sharees_fetched (QJsonDocument reply) {
        GLib.Vector<unowned<Sharee>> new_sharees;
     {
            const string[] sharee_types {"users", "groups", "emails", "remotes", "circles", "rooms"};

            const var append_sharees = [this, sharee_types] (QJsonObject data, GLib.Vector<unowned<Sharee>>& out) {
                for (var sharee_type : sharee_types) {
                    const var category = data.value (sharee_type).to_array ();
                    for (var sharee : category) {
                        out.append (parse_sharee (sharee.to_object ()));
                    }
                }
            };

            append_sharees (reply.object ().value ("ocs").to_object ().value ("data").to_object (), new_sharees);
            append_sharees (reply.object ().value ("ocs").to_object ().value ("data").to_object ().value ("exact").to_object (), new_sharees);
        }

        // Filter sharees that we have already shared with
        GLib.Vector<unowned<Sharee>> filtered_sharees;
        foreach (var sharee, new_sharees) {
            bool found = false;
            foreach (var blocklist_sharee, this.sharee_blocklist) {
                if (sharee.type () == blocklist_sharee.type () && sharee.share_with () == blocklist_sharee.share_with ()) {
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

    unowned<Sharee> Sharee_model.parse_sharee (QJsonObject data) {
        string display_name = data.value ("label").to_"";
        const string share_with = data.value ("value").to_object ().value ("share_with").to_"";
        Sharee.Type type = (Sharee.Type)data.value ("value").to_object ().value ("share_type").to_int ();
        const string additional_info = data.value ("value").to_object ().value ("share_with_additional_info").to_"";
        if (!additional_info.is_empty ()) {
            display_name = _("%1 (%2)", "sharee (share_with_additional_info)").arg (display_name, additional_info);
        }

        return unowned<Sharee> (new Sharee (share_with, display_name, type));
    }

    // Helper function for set_new_sharees   (could be a lambda when we can use them)
    static unowned<Sharee> sharee_from_model_index (QModelIndex idx) {
        return idx.data (Qt.User_role).value<unowned<Sharee>> ();
    }

    struct Find_sharee_helper {
        const unowned<Sharee> sharee;
        bool operator () (unowned<Sharee> s2) {
            return s2.format () == sharee.format () && s2.display_name () == sharee.format ();
        }
    };

    /* Set the new sharee

        Do that while preserving the model index so the selection stays
    ***********************************************************/
    void Sharee_model.set_new_sharees (GLib.Vector<unowned<Sharee>> new_sharees) {
        layout_about_to_be_changed ();
        const var persistent = persistent_index_list ();
        GLib.Vector<unowned<Sharee>> old_persistant_sharee;
        old_persistant_sharee.reserve (persistent.size ());

        std.transform (persistent.begin (), persistent.end (), std.back_inserter (old_persistant_sharee),
            sharee_from_model_index);

        this.sharees = new_sharees;

        QModel_index_list new_persistant;
        new_persistant.reserve (persistent.size ());
        foreach (unowned<Sharee> sharee, old_persistant_sharee) {
            Find_sharee_helper helper = {
                sharee
            };
            var it = std.find_if (this.sharees.const_begin (), this.sharees.const_end (), helper);
            if (it == this.sharees.const_end ()) {
                new_persistant << QModelIndex ();
            } else {
                new_persistant << index (std.distance (this.sharees.const_begin (), it));
            }
        }

        change_persistent_index_list (persistent, new_persistant);
        layout_changed ();
    }

    int Sharee_model.row_count (QModelIndex &) {
        return this.sharees.size ();
    }

    GLib.Variant Sharee_model.data (QModelIndex index, int role) {
        if (index.row () < 0 || index.row () > this.sharees.size ()) {
            return GLib.Variant ();
        }

        const var sharee = this.sharees.at (index.row ());
        if (role == Qt.Display_role) {
            return sharee.format ();

        } else if (role == Qt.Edit_role) {
            // This role is used by the completer - it should match
            // the full name and the user name and thus we include both
            // in the output here. But we need to take care this string
            // doesn't leak to the user.
            return string (sharee.display_name () + " (" + sharee.share_with () + ")");

        } else if (role == Qt.User_role) {
            return GLib.Variant.from_value (sharee);
        }

        return GLib.Variant ();
    }

    unowned<Sharee> Sharee_model.get_sharee (int at) {
        if (at < 0 || at > this.sharees.size ()) {
            return unowned<Sharee> (nullptr);
        }

        return this.sharees.at (at);
    }
    }
    