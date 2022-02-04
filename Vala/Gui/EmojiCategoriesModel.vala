/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtGlobal>
//  #include <memory>

//  #pragma once

//  #include <QQmlEngine>
//  #include <QAbstractItemModel>

namespace Occ {

class EmojiCategoriesModel : QAbstractListModel {

    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) override;
    public int row_count (QModelIndex parent = QModelIndex ()) override;
    public GLib.HashMap<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private enum Roles {
        EmojiRole = 0,
        LabelRole
    };

    /***********************************************************
    ***********************************************************/
    private struct Category {
        string emoji;
        string label;
    };

    /***********************************************************
    ***********************************************************/
    private static const GLib.Vector<Category> categories;
}



    GLib.Variant EmojiCategoriesModel.data (QModelIndex index, int role) {
        if (!index.is_valid ()) {
            return {};
        }

        switch (role) {
        case Roles.EmojiRole:
            return categories[index.row ()].emoji;

        case Roles.LabelRole:
            return categories[index.row ()].label;
        }

        return {};
    }

    int EmojiCategoriesModel.row_count (QModelIndex parent) {
        Q_UNUSED (parent);
        return static_cast<int> (categories.size ());
    }

    GLib.HashMap<int, GLib.ByteArray> EmojiCategoriesModel.role_names () {
        GLib.HashMap<int, GLib.ByteArray> roles;
        roles[Roles.EmojiRole] = "emoji";
        roles[Roles.LabelRole] = "label";
        return roles;
    }

    const GLib.Vector<EmojiCategoriesModel.Category> EmojiCategoriesModel.categories = {
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
