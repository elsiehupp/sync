/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>
@copyright GPLv3 or Later
***********************************************************/

//  #include <QtCore>
//  #include <limits>
//  #include <QtCore>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The UnifiedSearchResult class
@ingroup gui
Simple data structure that represents single Unified Search
result
***********************************************************/
struct UnifiedSearchResult {

    public enum Type {
        DEFAULT = "DEFAULT",
        FETCH_MORE_TRIGGER = "FETCH_MORE_TRIGGER",
    }

    string title;
    string subline;
    string provider_id;
    string provider_name;
    bool is_rounded = false;
    int32 order = int32.MAX;
    GLib.Uri resource_url;
    string icons;
    Type type = Type.DEFAULT;

} // struct UnifiedSearchResult

} // namespace Ui
} // namespace Occ
