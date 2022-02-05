/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QTreeView>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Folder_status_view class
@ingroup gui
***********************************************************/
class Folder_status_view : QTreeView {

    /***********************************************************
    ***********************************************************/
    public Folder_status_view (Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public QModelIndex index_at (QPoint point) override;
    public QRect visual_rect (QModelIndex index) override;
}

    Folder_status_view.Folder_status_view (Gtk.Widget parent) : QTreeView (parent) {
    }

    QModelIndex Folder_status_view.index_at (QPoint point) {
        QModelIndex index = QTreeView.index_at (point);
        if (index.data (DataRole.ADD_BUTTON).to_bool () && !visual_rect (index).contains (point)) {
            return {};
        }
        return index;
    }

    QRect Folder_status_view.visual_rect (QModelIndex index) {
        QRect rect = QTreeView.visual_rect (index);
        if (index.data (DataRole.ADD_BUTTON).to_bool ()) {
            return FolderStatusDelegate.add_button_rect (rect, layout_direction ());
        }
        return rect;
    }

    } // namespace Occ
    