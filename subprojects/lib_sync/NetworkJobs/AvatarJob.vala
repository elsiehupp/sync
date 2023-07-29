namespace Occ {
namespace LibSync {

//  #ifndef TOKEN_AUTH_ONLY
/***********************************************************
@class AvatarJob

@brief Retrieves the account users avatar from the server using a GET request.

If the server does not have the avatar, the result Pixmap is empty.

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class AvatarJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri avatar_url;


    /***********************************************************
    @brief signal_avatar_pixmap - returns either a valid pixmap or not.
    ***********************************************************/
    internal signal void signal_avatar_pixmap (Gtk.Image image);


    /***********************************************************
    @param user_id The user for which to obtain the avatar
    @param size The size of the avatar (square so size * size)
    ***********************************************************/
    public AvatarJob.for_account (Account account, string user_id, int size) {
        //  base (account, "");
        //  if (account.server_version_int >= Account.make_server_version (10, 0, 0)) {
        //      this.avatar_url = Utility.concat_url_path (account.url, "remote.php/dav/avatars/%1/%2.png".printf (user_id, string.number (size)));
        //  } else {
        //      this.avatar_url = Utility.concat_url_path (account.url, "index.php/avatar/%1/%2".printf (user_id, string.number (size)));
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  send_request ("GET", this.avatar_url, request);
        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    The retrieved avatar images don't have the circle shape by
    default
    ***********************************************************/
    public static Gtk.Image make_circular_avatar (Gtk.Image base_avatar) {
        //  if (base_avatar == null) {
        //      return null;
        //  }

        //  int dim = base_avatar.width ();

        //  Gtk.Image avatar = new Gtk.Image (dim, dim, Gtk.Image.FormatARGB32);
        //  avatar.fill (GLib.transparent);

        //  GLib.Painter painter = new GLib.Painter (avatar);
        //  painter.render_hint (GLib.Painter.Antialiasing);

        //  GLib.PainterPath path;
        //  path.add_ellipse (0, 0, dim, dim);
        //  painter.clip_path (path);

        //  painter.draw_image (0, 0, base_avatar);
        //  painter.end ();

        //  return avatar;
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        //  int http_result_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        //  Gtk.Image av_image;

        //  if (http_result_code == 200) {
        //      string png_data = this.reply.read_all ();
        //      if (png_data.size ()) {
        //          if (av_image.load_from_data (png_data)) {
        //              GLib.debug ("Retrieved Avatar pixmap!");
        //          }
        //      }
        //  }
        //  signal_avatar_pixmap (av_image);
        //  return true;
    }

} // class AvatarJob

} // namespace LibSync
} // namespace Occ
