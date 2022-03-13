/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtGlobal>
//  #include <memory>

//  #include <QQmlEngine>
//  #include <QAbstractItemModel>

namespace Occ {
namespace Ui {

class EmojiCategoriesModel : QAbstractListModel {


    /***********************************************************
    ***********************************************************/
    private enum Roles {
        EMOJI_ROLE = 0,
        LABEL_ROLE
    }


    /***********************************************************
    ***********************************************************/
    private struct Category {
        string emoji;
        string label;
    }


    /***********************************************************
    ***********************************************************/
    private const GLib.Vector<Category> CATEGORIES = {
        {
            "⌛️",
            "history"
        },
        {
            "😏",
            "people"
        },
        {
            "🌲",
            "nature"
        },
        {
            "🍛",
            "food"
        },
        {
            "🚁",
            "activity"
        },
        {
            "🚅",
            "travel"
        },
        {
            "💡",
            "objects"
        },
        {
            "🔣",
            "symbols"
        },
        {
            "🏁",
            "flags"
        },
    };

    /***********************************************************
    ***********************************************************/
    public override GLib.Variant data (QModelIndex index, int role) {
        if (!index.is_valid ()) {
            return {};
        }

        switch (role) {
        case Roles.EMOJI_ROLE:
            return CATEGORIES[index.row ()].emoji;

        case Roles.LABEL_ROLE:
            return CATEGORIES[index.row ()].label;
        }

        return {};
    }


    /***********************************************************
    ***********************************************************/
    public override int row_count (QModelIndex parent = QModelIndex ()) {
        //  Q_UNUSED (parent);
        return static_cast<int> (CATEGORIES.size ());
    }


    /***********************************************************
    ***********************************************************/
    public override GLib.HashMap<int, GLib.ByteArray> role_names () {
        GLib.HashMap<int, GLib.ByteArray> roles;
        roles[Roles.EMOJI_ROLE] = "emoji";
        roles[Roles.LABEL_ROLE] = "label";
        return roles;
    }

} // class EmojiCategoriesModel

} // namespace Ui
} // namespace Occ
