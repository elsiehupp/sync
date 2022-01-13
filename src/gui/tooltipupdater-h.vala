/*
Copyright (C) by Christian Kamm <mail@ckamm.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QPoint>

class QModelIndex;

namespace Occ {

/**
@brief Updates tooltips of items in a QTreeView when they change.
@ingroup gui

Usually tooltips are not updated as they change. Since we want
use tooltips to show rapidly updating progress information, we
need to make sure
as it changes.

To accomplish that, the eventFilter () stores the tooltip's position
and the dataChanged () slot updates the tooltip if Qt.ToolTipRole
gets updated while a tooltip is shown.
*/
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
