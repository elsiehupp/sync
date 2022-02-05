/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonObject>
//  #include <QJsonDocument>
//  #include <QJsonArray>
//  #include <QFlags>
//  #include <QAbstractListMode
//  #include <QLoggingCategory>
//  #include <QModelIndex>


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
    }

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
}


    Sharee.Sharee (string share_with,
        const string display_name,
        const Type type)
        : this.share_with (share_with)
        this.display_name (display_name)
        this.type (type) {
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

    }
    