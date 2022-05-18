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

public class EmojiCategoriesModel : GLib.Object {


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
    private GLib.HashTable<string, string> category_hash_table = new GLib.HashTable<string, string> (str_hash, str_equal);
    category_hash_table.set (
        "⌛️",
        "history"
    );
    category_hash_table.set (
        "😏",
        "people"
    );
    category_hash_table.set (
        "🌲",
        "nature"
    );
    category_hash_table.set (
        "🍛",
        "food"
    );
    category_hash_table.set (
        "🚁",
        "activity"
    );
    category_hash_table.set (
        "🚅",
        "travel"
    );
    category_hash_table.set (
        "💡",
        "objects"
    );
    category_hash_table.set (
        "🔣",
        "symbols"
    );
    category_hash_table.set (
        "🏁",
        "flags"
    );

    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (int index, int role) {
        if (!index.is_valid) {
            return null;
        }

        switch (role) {
        case Roles.EMOJI_ROLE:
            return category_hash_table.get (index.row ());

        case Roles.LABEL_ROLE:
            return category_hash_table.get (index.row ()).key;
        }

        return null;
    }


    /***********************************************************
    ***********************************************************/
    public int row_count (GLib.ModelIndex parent = GLib.ModelIndex ()) {
        //  Q_UNUSED (parent);
        return (int)category_hash_table.size ();
    }

} // class EmojiCategoriesModel

} // namespace Ui
} // namespace Occ
