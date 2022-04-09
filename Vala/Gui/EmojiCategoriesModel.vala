/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QtGlobal>
//  #include <memory>

//  #include <GLib.QmlEngine>
//  #include <GLib.AbstractItemModel>

namespace Occ {
namespace Ui {

public class EmojiCategoriesModel : GLib.AbstractListModel {


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
    private GLib.List<Category> CATEGORIES = {
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
    public override GLib.Variant data (GLib.ModelIndex index, int role) {
        if (!index.is_valid) {
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
    public override int row_count (GLib.ModelIndex parent = GLib.ModelIndex ()) {
        //  Q_UNUSED (parent);
        return (int)CATEGORIES.size ();
    }


    /***********************************************************
    ***********************************************************/
    public override GLib.HashTable<int, string> role_names () {
        GLib.HashTable<int, string> roles;
        roles[Roles.EMOJI_ROLE] = "emoji";
        roles[Roles.LABEL_ROLE] = "label";
        return roles;
    }

} // class EmojiCategoriesModel

} // namespace Ui
} // namespace Occ
