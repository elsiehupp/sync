/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QPoint>


namespace Occ {

/***********************************************************
@brief Updates tooltips of items in a QTreeView when they change.
@ingroup gui

Usually tooltips are not updated as they change. Since we want
use tooltips to show rapidly updating progress information, we
need to make sure
as it changes.

To accomplish that, the eventFilter () stores the tooltip's position
and the dataChanged () slot updates the tooltip if Qt.ToolTipRole
gets updated while a tooltip is shown.
***********************************************************/
class ToolTipUpdater : GLib.Object {
public:
    ToolTipUpdater (QTreeView *treeView);

protected:
    bool eventFilter (GLib.Object *obj, QEvent *ev) override;

private slots:
    void dataChanged (QModelIndex &topLeft, QModelIndex &bottomRight, QVector<int> &roles);

private:
    QTreeView *_treeView;
    QPoint _toolTipPos;
};

} // namespace Occ











/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTreeView>
// #include <QHelpEvent>
// #include <QToolTip>

using namespace Occ;

ToolTipUpdater.ToolTipUpdater (QTreeView *treeView)
    : GLib.Object (treeView)
    , _treeView (treeView) {
    connect (_treeView.model (), &QAbstractItemModel.dataChanged,
        this, &ToolTipUpdater.dataChanged);
    _treeView.viewport ().installEventFilter (this);
}

bool ToolTipUpdater.eventFilter (GLib.Object * /*obj*/, QEvent *ev) {
    if (ev.type () == QEvent.ToolTip) {
        auto *helpEvent = static_cast<QHelpEvent> (ev);
        _toolTipPos = helpEvent.globalPos ();
    }
    return false;
}

void ToolTipUpdater.dataChanged (QModelIndex &topLeft,
    const QModelIndex &bottomRight,
    const QVector<int> &roles) {
    if (!QToolTip.isVisible () || !roles.contains (Qt.ToolTipRole) || _toolTipPos.isNull ()) {
        return;
    }

    // Was it the item under the cursor that changed?
    auto index = _treeView.indexAt (_treeView.mapFromGlobal (QCursor.pos ()));
    if (topLeft == bottomRight && index != topLeft) {
        return;
    }

    // Update the currently active tooltip
    QToolTip.showText (_toolTipPos, _treeView.model ().data (index, Qt.ToolTipRole).toString ());
}
