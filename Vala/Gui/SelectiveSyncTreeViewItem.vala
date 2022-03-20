/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class SelectiveSyncTreeViewItem : QTreeWidgetItem {

    /***********************************************************
    ***********************************************************/
    public SelectiveSyncTreeViewItem (int type = QTreeWidgetItem.Type) {
        base (type);
    }


    /***********************************************************
    ***********************************************************/
    public SelectiveSyncTreeViewItem.with_parent (QTreeWidgetItem parent, int type = QTreeWidgetItem.Type) {
        base (parent, type);
    }


    /***********************************************************
    ***********************************************************/
    public SelectiveSyncTreeViewItem.for_string_list (string[] strings, int type = QTreeWidgetItem.Type) {

    }


    /***********************************************************
    ***********************************************************/
    //  public TreeWidgetItem (view, type) {

    //  }


    /***********************************************************
    ***********************************************************/
    //  private bool operator< (QTreeWidgetItem other) override {
    //      int column = tree_widget ().sort_column ();
    //      if (column == 1) {
    //          return data (1, Qt.USER_ROLE).to_long_long () < other.data (1, Qt.USER_ROLE).to_long_long ();
    //      }
    //      return QTreeWidgetItem.operator< (other);
    //  }

} // class SelectiveSyncTreeViewItem

} // namespace Testing
} // namespace Occ
