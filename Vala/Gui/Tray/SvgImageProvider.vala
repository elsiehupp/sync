/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>

//  #pragma once

//  #include <QQuick_image_provider>

namespace Occ {
namespace Ui {

class Svg_image_provider : QQuick_image_provider {

    /***********************************************************
    ***********************************************************/
    public Svg_image_provider ();

    /***********************************************************
    ***********************************************************/
    public QImage request_image (string identifier, QSize size, QSize requested_size) override;
}


    Svg_image_provider.Svg_image_provider ()
        : QQuick_image_provider (QQuick_image_provider.Image) {
    }

    QImage Svg_image_provider.request_image (string identifier, QSize size, QSize requested_size) {
        //  Q_ASSERT (!identifier.is_empty ());

        const var id_split = identifier.split (QStringLiteral ("/"), Qt.Skip_empty_parts);

        if (id_split.is_empty ()) {
            GLib.warn (lc_svg_image_provider) << "Image identifier is incorrect!";
            return {};
        }

        const var pixmap_name = id_split.at (0);
        const var pixmap_color = id_split.size () > 1 ? Gtk.Color (id_split.at (1)) : QColor_constants.Svg.black;

        if (pixmap_name.is_empty () || !pixmap_color.is_valid ()) {
            GLib.warn (lc_svg_image_provider) << "Image identifier is incorrect!";
            return {};
        }

        return Icon_utils.create_svg_image_with_custom_color (pixmap_name, pixmap_color, size, requested_size);
    }
}
}
