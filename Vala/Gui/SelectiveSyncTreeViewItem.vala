/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class SelectiveSyncTreeViewItem : QTreeWidgetItem {

    /***********************************************************
    ***********************************************************/
    public SelectiveSyncTreeViewItem (int type = QTreeWidgetItem.Type)
        : QTreeWidgetItem (type) {
    }


    /***********************************************************
    ***********************************************************/
    public SelectiveSyncTreeViewItem (string[] strings, int type = QTreeWidgetItem.Type)
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public TreeWidgetItem (view, type) {
    }
    public SelectiveSyncTreeViewItem (QTreeWidgetItem parent, int type = QTreeWidgetItem.Type)
        : QTreeWidgetItem (parent, type) {
    }


    /***********************************************************
    ***********************************************************/
    private bool operator< (QTreeWidgetItem other) override {
        int column = tree_widget ().sort_column ();
        if (column == 1) {
            return data (1, Qt.USER_ROLE).to_long_long () < other.data (1, Qt.USER_ROLE).to_long_long ();
        }
        return QTreeWidgetItem.operator< (other);
    }
};