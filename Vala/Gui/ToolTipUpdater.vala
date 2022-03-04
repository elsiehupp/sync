/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QTreeView>
//  #include <QHelp_event>
//  #include <QToolTip>
//  #include <QPoint>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Updates tooltips of items in a QTreeView when they change.
@ingroup gui

Usually tooltips are not updated as they change. Since we want
use tooltips to show rapidly updating progress information, we
need to make sure
as it changes.

To accomplish that, the event_filter () stores the tooltip's position
and the on_signal_data_changed () slot updates the tooltip if Qt.ToolTipRole
gets updated while a tooltip is shown.
***********************************************************/
class ToolTipUpdater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public ToolTipUpdater (QTreeView tree_view);


    protected bool event_filter (GLib.Object obj, QEvent ev) override;


    /***********************************************************
    ***********************************************************/
    private void on_signal_data_changed (QModelIndex top_left, QModelIndex bottom_right, GLib.Vector<int> roles);

    /***********************************************************
    ***********************************************************/
    private 
    private QTreeView this.tree_view;
    private QPoint this.tool_tip_pos;
}

} // namespace Occ












using Occ;

ToolTipUpdater.ToolTipUpdater (QTreeView tree_view)
    : GLib.Object (tree_view)
    this.tree_view (tree_view) {
    connect (this.tree_view.model (), &QAbstractItemModel.on_signal_data_changed,
        this, &ToolTipUpdater.on_signal_data_changed);
    this.tree_view.viewport ().install_event_filter (this);
}

bool ToolTipUpdater.event_filter (GLib.Object * /*obj*/, QEvent ev) {
    if (ev.type () == QEvent.Tool_tip) {
        var help_event = static_cast<QHelp_event> (ev);
        this.tool_tip_pos = help_event.global_pos ();
    }
    return false;
}

void ToolTipUpdater.on_signal_data_changed (QModelIndex top_left,
    const QModelIndex bottom_right,
    const GLib.Vector<int> roles) {
    if (!QToolTip.is_visible () || !roles.contains (Qt.ToolTipRole) || this.tool_tip_pos.is_null ()) {
        return;
    }

    // Was it the item under the cursor that changed?
    var index = this.tree_view.index_at (this.tree_view.map_from_global (QCursor.position ()));
    if (top_left == bottom_right && index != top_left) {
        return;
    }

    // Update the currently active tooltip
    QToolTip.show_text (this.tool_tip_pos, this.tree_view.model ().data (index, Qt.ToolTipRole).to_string ());
}
