/***********************************************************
@author Christian Kamm <mail@ckamm.de>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.TreeView>
//  #include <GLib.Help_event>
//  #include <GLib.ToolTip>
//  #include <GLib.Point>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Updates tooltips of items in a GLib.TreeView when they change.
@ingroup gui

Usually tooltips are not updated as they change. Since we want
use tooltips to show rapidly updating progress information, we
need to make sure
as it changes.

To accomplish that, the event_filter () stores the tooltip's position
and the on_signal_data_changed () slot updates the tooltip if GLib.ToolTipRole
gets updated while a tooltip is shown.
***********************************************************/
public class ToolTipUpdater { //: GLib.Object {

//    /***********************************************************
//    ***********************************************************/
//    private GLib.TreeView tree_view;
//    private GLib.Point tool_tip_pos;

//    /***********************************************************
//    ***********************************************************/
//    public ToolTipUpdater (GLib.TreeView tree_view) {
//        base (tree_view);
//        this.tree_view = tree_view;
//        this.tree_view.model ().signal_data_changed.connect (
//            this.on_signal_data_changed
//        );
//        this.tree_view.viewport ().install_event_filter (this);
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected override bool event_filter (GLib.Object object, Gdk.Event event) {
//        if (event.type == Gdk.Event.Tool_tip) {
//            var help_event = (GLib.Help_event)event;
//            this.tool_tip_pos = help_event.global_pos ();
//        }
//        return false;
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_data_changed (GLib.ModelIndex top_left, GLib.ModelIndex bottom_right, GLib.List<int> roles) {
//        if (!GLib.ToolTip.is_visible () || !roles.contains (GLib.ToolTipRole) || this.tool_tip_pos == null) {
//            return;
//        }

//        // Was it the item under the cursor that changed?
//        var index = this.tree_view.index_at (this.tree_view.map_from_global (GLib.Cursor.position ()));
//        if (top_left == bottom_right && index != top_left) {
//            return;
//        }

//        // Update the currently active tooltip
//        GLib.ToolTip.show_text (this.tool_tip_pos, this.tree_view.model ().data (index, GLib.ToolTipRole).to_string ());
//    }

} // class ToolTipUpdater

} // namespace Ui
} // namespace Occ
