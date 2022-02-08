
namespace Occ {
namespace Ui {

class ImageProvider : QQuickImageProvider {

    /***********************************************************
    ***********************************************************/
    public ImageProvider () {
        base (QQuickImageProvider.Image);
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image request_image (string identifier, QSize size, QSize requested_size) {
        //  Q_UNUSED (size)
        //  Q_UNUSED (requested_size)

        const var make_icon = [] (string path) {
            Gtk.Image image (128, 128, Gtk.Image.Format_ARGB32);
            image.fill (Qt.Global_color.transparent);
            QPainter painter (&image);
            QSvgRenderer renderer (path);
            renderer.render (&painter);
            return image;
        }

        if (identifier == QLatin1String ("fallback_white")) {
            return make_icon (QStringLiteral (":/client/theme/white/user.svg"));
        }

        if (identifier == QLatin1String ("fallback_black")) {
            return make_icon (QStringLiteral (":/client/theme/black/user.svg"));
        }

        const int uid = identifier.to_int ();
        return UserModel.instance ().avatar_by_identifier (uid);
    }

} // class ImageProvider

} // namespace Ui
} // namespace Occ
