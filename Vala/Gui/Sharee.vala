/***********************************************************
@author Roeland Jago Douma <roeland@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

//  #include <QJsonObject>
//  #include <QJsonDocument>
//  #include <QJsonArray>
//  #include <QFlags>
//  #include <QAbstractListMode
//  #include <QLoggingCategory>
//  #include <QModelIndex>

namespace Occ {
namespace Ui {

public class Sharee : GLib.Object {

    /***********************************************************
    Keep in sync with Share.Type
    ***********************************************************/
    public enum Type {
        USER = 0,
        GROUP = 1,
        EMAIL = 4,
        FEDERATED = 6,
        CIRCLE = 7,
        ROOM = 10
    }


    /***********************************************************
    ***********************************************************/
    string share_with { public get; private set; }
    string display_name { public get; private set; }
    Type type { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public Sharee (string share_with,
        string display_name,
        Type type) {
        this.share_with = share_with;
        this.display_name = display_name;
        this.type = type;
    }


    /***********************************************************
    ***********************************************************/
    public string to_string () {
        string formatted = this.display_name;

        if (this.type == Type.GROUP) {
            formatted += " (group)";
        } else if (this.type == Type.EMAIL) {
            formatted += " (email)";
        } else if (this.type == Type.FEDERATED) {
            formatted += " (remote)";
        } else if (this.type == Type.CIRCLE) {
            formatted += " (circle)";
        } else if (this.type == Type.ROOM) {
            formatted += " (conversation)";
        }

        return formatted;
    }

} // class Sharee

} // namespace Ui
} // namespace Occ
