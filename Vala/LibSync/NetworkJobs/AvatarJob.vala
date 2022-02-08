/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
/***********************************************************
@brief Retrieves the account users avatar from the server using a GET request.

If the server does not have the avatar, the result Pixmap is empty.

@ingroup libsync
***********************************************************/
class AvatarJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri avatar_url;


    /***********************************************************
    @brief avatar_pixmap - returns either a valid pixmap or not.
    ***********************************************************/
    signal void avatar_pixmap (Gtk.Image image);


    /***********************************************************
    @param user_id The user for which to obtain the avatar
    @param size The size of the avatar (square so size * size)
    ***********************************************************/
    public AvatarJob (AccountPointer account, string user_id, int size, GLib.Object parent = new GLib.Object ()) {
        base (account, "", parent);
        if (account.server_version_int () >= Account.make_server_version (10, 0, 0)) {
            this.avatar_url = Utility.concat_url_path (account.url (), string ("remote.php/dav/avatars/%1/%2.png").arg (user_id, string.number (size)));
        } else {
            this.avatar_url = Utility.concat_url_path (account.url (), string ("index.php/avatar/%1/%2").arg (user_id, string.number (size)));
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () override {
        Soup.Request req;
        send_request ("GET", this.avatar_url, req);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    The retrieved avatar images don't have the circle shape by
    default
    ***********************************************************/
    public static Gtk.Image make_circular_avatar (Gtk.Image base_avatar) {
        if (base_avatar.is_null ()) {
            return {};
        }

        int dim = base_avatar.width ();

        Gtk.Image avatar (dim, dim, Gtk.Image.Format_ARGB32);
        avatar.fill (Qt.transparent);

        QPainter painter (&avatar);
        painter.render_hint (QPainter.Antialiasing);

        QPainterPath path;
        path.add_ellipse (0, 0, dim, dim);
        painter.clip_path (path);

        painter.draw_image (0, 0, base_avatar);
        painter.end ();

        return avatar;
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () override {
        int http_result_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        Gtk.Image av_image;

        if (http_result_code == 200) {
            GLib.ByteArray png_data = reply ().read_all ();
            if (png_data.size ()) {
                if (av_image.load_from_data (png_data)) {
                    GLib.debug ("Retrieved Avatar pixmap!";
                }
            }
        }
        /* emit */ (avatar_pixmap (av_image));
        return true;
    }

} // class AvatarJob
//  #endif

} // namespace Occ
