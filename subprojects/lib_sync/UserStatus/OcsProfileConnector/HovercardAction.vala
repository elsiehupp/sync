namespace Occ {
namespace LibSync {

/***********************************************************
@class HovercardAction
***********************************************************/
public class HovercardAction { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public string title;
    public GLib.Uri icon_url;
    public Gdk.Pixbuf icon;
    public GLib.Uri link;

    /***********************************************************
    ***********************************************************/
    public HovercardAction (string title, GLib.Uri icon_url, GLib.Uri link) {
        //  this.title = std.move (title);
        //  this.icon_url = std.move (icon_url);
        //  this.link = std.move (link);
    }

} // class HovercardAction

} // namespace LibSync
} // namespace Occ
