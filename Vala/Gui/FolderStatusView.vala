/***********************************************************
@author 2018 by J-P Nurmi <jpnurmi@gmail.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.TreeView>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderStatusView class
@ingroup gui
***********************************************************/
public class FolderStatusView { //: GLib.TreeView {

    /***********************************************************
    ***********************************************************/
    public FolderStatusView (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ModelIndex index_at (GLib.Point point) {
        //  GLib.ModelIndex index = GLib.TreeView.index_at (point);
        //  if (index.data (DataRole.ADD_BUTTON).to_bool () && !visual_rect (index).contains (point)) {
        //      return {};
        //  }
        //  return index;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Rect visual_rect (GLib.ModelIndex index)  {
        //  GLib.Rect rect = GLib.TreeView.visual_rect (index);
        //  if (index.data (DataRole.ADD_BUTTON).to_bool ()) {
        //      return FolderStatusDelegate.add_button_rect (rect, layout_direction ());
        //  }
        //  return rect;
    }

} // class FolderStatusView

} // namespace Ui
} // namespace Occ
