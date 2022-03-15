/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QTreeView>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderStatusView class
@ingroup gui
***********************************************************/
public class FolderStatusView : QTreeView {

    /***********************************************************
    ***********************************************************/
    public FolderStatusView (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public QModelIndex index_at (QPoint point) {
        QModelIndex index = QTreeView.index_at (point);
        if (index.data (DataRole.ADD_BUTTON).to_bool () && !visual_rect (index).contains (point)) {
            return {};
        }
        return index;
    }


    /***********************************************************
    ***********************************************************/
    public QRect visual_rect (QModelIndex index)  {
        QRect rect = QTreeView.visual_rect (index);
        if (index.data (DataRole.ADD_BUTTON).to_bool ()) {
            return FolderStatusDelegate.add_button_rect (rect, layout_direction ());
        }
        return rect;
    }

} // class FolderStatusView

} // namespace Ui
} // namespace Occ
