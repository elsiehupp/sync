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
public class ToolTipUpdater : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private QTreeView tree_view;
    private QPoint tool_tip_pos;

    /***********************************************************
    ***********************************************************/
    public ToolTipUpdater (QTreeView tree_view) {
        base (tree_view);
        this.tree_view = tree_view;
        this.tree_view.model ().signal_data_changed.connect (
            this.on_signal_data_changed
        );
        this.tree_view.viewport ().install_event_filter (this);
    }


    /***********************************************************
    ***********************************************************/
    protected override bool event_filter (GLib.Object object, QEvent ev) {
        if (ev.type () == QEvent.Tool_tip) {
            var help_event = static_cast<QHelp_event> (ev);
            this.tool_tip_pos = help_event.global_pos ();
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_data_changed (QModelIndex top_left, QModelIndex bottom_right, GLib.List<int> roles) {
        if (!QToolTip.is_visible () || !roles.contains (Qt.ToolTipRole) || this.tool_tip_pos == null) {
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

} // class ToolTipUpdater

} // namespace Ui
} // namespace Occ
