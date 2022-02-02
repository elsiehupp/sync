/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class Selective_sync_tree_view_item : QTree_widget_item {

    /***********************************************************
    ***********************************************************/
    public Selective_sync_tree_view_item (int type = QTree_widget_item.Type)
        : QTree_widget_item (type) {
    }


    /***********************************************************
    ***********************************************************/
    public Selective_sync_tree_view_item (string[] strings, int type = QTree_widget_item.Type)
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public Tree_widget_item (view, type) {
    }
    public Selective_sync_tree_view_item (QTree_widget_item parent, int type = QTree_widget_item.Type)
        : QTree_widget_item (parent, type) {
    }


    /***********************************************************
    ***********************************************************/
    private bool operator< (QTree_widget_item other) override {
        int column = tree_widget ().sort_column ();
        if (column == 1) {
            return data (1, Qt.User_role).to_long_long () < other.data (1, Qt.User_role).to_long_long ();
        }
        return QTree_widget_item.operator< (other);
    }
};