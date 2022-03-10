/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QQuickImageProvider>

namespace Occ {
namespace Ui {

class SvgImageProvider : QQuickImageProvider {

    /***********************************************************
    ***********************************************************/
    public SvgImageProvider () {
        base (QQuickImageProvider.Image);
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image request_image (string identifier, QSize size, QSize requested_size) {
        //  Q_ASSERT (!identifier.is_empty ());

        const var id_split = identifier.split ("/", Qt.SkipEmptyParts);

        if (id_split.is_empty ()) {
            GLib.warning ("Image identifier is incorrect!");
            return {};
        }

        const var pixmap_name = id_split.at (0);
        const var pixmap_color = id_split.size () > 1 ? Gtk.Color (id_split.at (1)) : QColor_constants.Svg.black;

        if (pixmap_name.is_empty () || !pixmap_color.is_valid ()) {
            GLib.warning ("Image identifier is incorrect!");
            return {};
        }

        return IconUtils.create_svg_image_with_custom_color (pixmap_name, pixmap_color, size, requested_size);
    }

} // class SvgImageProvider

} // namespace Ui
} // namespace Occ
