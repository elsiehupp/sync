/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QTreeView>

namespace Occ {

/***********************************************************
@brief The FolderStatusView class
@ingroup gui
***********************************************************/
class FolderStatusView : QTreeView {

public:
    FolderStatusView (Gtk.Widget *parent = nullptr);

    QModelIndex indexAt (QPoint &point) const override;
    QRect visualRect (QModelIndex &index) const override;
};

} // namespace Occ







namespace Occ {

    FolderStatusView.FolderStatusView (Gtk.Widget *parent) : QTreeView (parent) {
    }
    
    QModelIndex FolderStatusView.indexAt (QPoint &point) {
        QModelIndex index = QTreeView.indexAt (point);
        if (index.data (FolderStatusDelegate.AddButton).toBool () && !visualRect (index).contains (point)) {
            return {};
        }
        return index;
    }
    
    QRect FolderStatusView.visualRect (QModelIndex &index) {
        QRect rect = QTreeView.visualRect (index);
        if (index.data (FolderStatusDelegate.AddButton).toBool ()) {
            return FolderStatusDelegate.addButtonRect (rect, layoutDirection ());
        }
        return rect;
    }
    
    } // namespace Occ
    