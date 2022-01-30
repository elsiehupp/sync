/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>

// #include <GLib.File>
// #include <QLoggingCategory>
// #include <QPainter>
// #include <QPixmapCache>
// #include <QSvgRenderer>

// #include <QColor>
// #include <QPixmap>

namespace {
    string find_svg_file_path (string file_name, string[] &possible_colors) {
        string result;
        result = string{Occ.Theme.theme_prefix} + file_name;
        if (GLib.File.exists (result)) {
            return result;
        } else {
            for (var &color : possible_colors) {
                result = string{Occ.Theme.theme_prefix} + color + QStringLiteral ("/") + file_name;

                if (GLib.File.exists (result)) {
                    return result;
                }
            }
            result.clear ();
        }

        return result;
    }
}

namespace Occ {
namespace Ui {
namespace Icon_utils {

QPixmap pixmap_for_background (string file_name, QColor &background_color);
QImage create_svg_image_with_custom_color (string file_name, QColor &custom_color, QSize original_size = nullptr, QSize &requested_size = {});
QPixmap create_svg_pixmap_with_custom_color_cached (string file_name, QColor &custom_color, QSize original_size = nullptr, QSize &requested_size = {});
QImage draw_svg_with_custom_fill_color (string source_svg_path, QColor &fill_color, QSize original_size = nullptr, QSize &requested_size = {});

    QPixmap pixmap_for_background (string file_name, QColor &background_color) {
        Q_ASSERT (!file_name.is_empty ());

        const var pixmap_color = background_color.is_valid () && !Theme.is_dark_color (background_color)
            ? QColor_constants.Svg.black
            : QColor_constants.Svg.white;
        ;
        return create_svg_pixmap_with_custom_color_cached (file_name, pixmap_color);
    }

    QImage create_svg_image_with_custom_color (string file_name, QColor &custom_color, QSize original_size, QSize &requested_size) {
        Q_ASSERT (!file_name.is_empty ());
        Q_ASSERT (custom_color.is_valid ());

        QImage result{};

        if (file_name.is_empty () || !custom_color.is_valid ()) {
            q_warning (lc_icon_utils) << "invalid file_name or custom_color";
            return result;
        }

        // some icons are present in white or black only, so, we need to check both when needed
        const var icon_base_colors = string[]{QStringLiteral ("black"), QStringLiteral ("white")};

        // check if there is an existing image matching the custom color {
            const var custom_color_name = [&custom_color] () {
                var result = custom_color.name ();
                if (result.starts_with (QStringLiteral ("#"))) {
                    if (result == QStringLiteral ("#000000")) {
                        result = QStringLiteral ("black");
                    }
                    if (result == QStringLiteral ("#ffffff")) {
                        result = QStringLiteral ("white");
                    }
                }
                return result;
            } ();

            if (icon_base_colors.contains (custom_color_name)) {
                result = QImage{string{Occ.Theme.theme_prefix} + custom_color_name + QStringLiteral ("/") + file_name};
                if (!result.is_null ()) {
                    return result;
                }
            }
        }

        // find the first matching svg file
        const var source_svg = find_svg_file_path (file_name, icon_base_colors);

        Q_ASSERT (!source_svg.is_empty ());
        if (source_svg.is_empty ()) {
            q_warning (lc_icon_utils) << "Failed to find base SVG file for" << file_name;
            return result;
        }

        result = draw_svg_with_custom_fill_color (source_svg, custom_color, original_size, requested_size);

        Q_ASSERT (!result.is_null ());
        if (result.is_null ()) {
            q_warning (lc_icon_utils) << "Failed to load pixmap for" << file_name;
        }

        return result;
    }

    QPixmap create_svg_pixmap_with_custom_color_cached (string file_name, QColor &custom_color, QSize original_size, QSize &requested_size) {
        QPixmap cached_pixmap;

        const var custom_color_name = custom_color.name ();

        const string cache_key = file_name + QStringLiteral (",") + custom_color_name;

        // check for existing QPixmap in cache
        if (QPixmapCache.find (cache_key, &cached_pixmap)) {
            if (original_size) {
                *original_size = {};
            }
            return cached_pixmap;
        }

        cached_pixmap = QPixmap.from_image (create_svg_image_with_custom_color (file_name, custom_color, original_size, requested_size));

        if (!cached_pixmap.is_null ()) {
            QPixmapCache.insert (cache_key, cached_pixmap);
        }

        return cached_pixmap;
    }

    QImage draw_svg_with_custom_fill_color (
        const string source_svg_path, QColor &fill_color, QSize original_size, QSize &requested_size) {
        QSvgRenderer svg_renderer;

        if (!svg_renderer.on_load (source_svg_path)) {
            GLib.warn (lc_icon_utils) << "Could no load initial SVG image";
            return {};
        }

        const var req_size = requested_size.is_valid () ? requested_size : svg_renderer.default_size ();

        if (original_size) {
            *original_size = svg_renderer.default_size ();
        }

        // render source image
        QImage svg_image (req_size, QImage.Format_ARGB32); {
            QPainter svg_image_painter (&svg_image);
            svg_image.fill (Qt.Global_color.transparent);
            svg_renderer.render (&svg_image_painter);
        }

        // draw target image with custom fill_color
        QImage image (req_size, QImage.Format_ARGB32);
        image.fill (QColor (fill_color)); {
            QPainter image_painter (&image);
            image_painter.set_composition_mode (QPainter.Composition_mode_Destination_in);
            image_painter.draw_image (0, 0, svg_image);
        }

        return image;
    }
    }
    }
    }
    