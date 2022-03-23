/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <theme.h>
//  #include <QLoggingC
//  #include <QPainter>
//  #include <QPixmapCache>
//  #include <QSvgRender
//  #include <Gdk.RGBA>
//  #include <Gdk.Pixbuf>

namespace Occ {
namespace Ui {

public class IconUtils : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public static string find_svg_file_path (string filename, GLib.List<string> possible_colors) {
        string result = Theme.THEME_PREFIX + filename;
        if (GLib.File.exists (result)) {
            return result;
        } else {
            foreach (var color in possible_colors) {
                result = Theme.THEME_PREFIX.to_string () + color + "/" + filename;

                if (GLib.File.exists (result)) {
                    return result;
                }
            }
            result == "";
        }

        return result;
    }


    /***********************************************************
    ***********************************************************/
    public static Gdk.Pixbuf pixmap_for_background (string filename, Gdk.RGBA background_color) {
        //  Q_ASSERT (!filename == "");

        const var pixmap_color = background_color.is_valid && !Theme.is_dark_color (background_color)
            ? QColor_constants.Svg.black
            : QColor_constants.Svg.white;
        ;
        return create_svg_pixmap_with_custom_color_cached (filename, pixmap_color);
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.Image create_svg_image_with_custom_color (string filename, Gdk.RGBA custom_color, Gdk.Rectangle original_size = null, Gdk.Rectangle requested_size = {}) {
        //  Q_ASSERT (!filename == "");
        //  Q_ASSERT (custom_color.is_valid);

        Gtk.Image result = new Gtk.Image ();

        if (filename == "" || !custom_color.is_valid) {
            GLib.warning ("invalid filename or custom_color");
            return result;
        }

        // some icons are present in white or black only, so, we need to check both when needed
        const GLib.List<string> icon_base_colors = {
            "black",
            "white"
        };


        if (icon_base_colors.contains (custom_color_name)) {
            result = new Gtk.Image (
                Theme.THEME_PREFIX + custom_color_name + "/" + filename
            );
            if (result != null) {
                return result;
            }
        }


        // find the first matching svg file
        const var source_svg = find_svg_file_path (filename, icon_base_colors);

        //  Q_ASSERT (!source_svg == "");
        if (source_svg == "") {
            GLib.warning ("Failed to find base SVG file for " + filename);
            return result;
        }

        result = draw_svg_with_custom_fill_color (source_svg, custom_color, original_size, requested_size);

        //  Q_ASSERT (!result == null);
        if (result == null) {
            GLib.warning ("Failed to load pixmap for " + filename);
        }

        return result;
    }


    /***********************************************************
    check if there is an existing image matching the custom color
    ***********************************************************/
    private static string custom_color_name (string custom_color) {
        var result = custom_color.name ();
        if (result.has_prefix ("#")) {
            if (result == "#000000") {
                result = "black";
            }
            if (result == "#ffffff") {
                result = "white";
            }
        }
        return result;
    }


    /***********************************************************
    ***********************************************************/
    public static Gdk.Pixbuf create_svg_pixmap_with_custom_color_cached (string filename, Gdk.RGBA custom_color, Gdk.Rectangle original_size = null, Gdk.Rectangle requested_size = {}) {
        Gdk.Pixbuf cached_pixmap;

        const var custom_color_name = custom_color.name ();

        const string cache_key = filename + "," + custom_color_name.to_string ();

        // check for existing Gdk.Pixbuf in cache
        if (QPixmapCache.find (cache_key, cached_pixmap)) {
            if (*original_size != null) {
                *original_size = {};
            }
            return cached_pixmap;
        }

        cached_pixmap = Gdk.Pixbuf.from_image (create_svg_image_with_custom_color (filename, custom_color, original_size, requested_size));

        if (cached_pixmap != null) {
            QPixmapCache.insert (cache_key, cached_pixmap);
        }

        return cached_pixmap;
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.Image draw_svg_with_custom_fill_color (string source_svg_path, Gdk.RGBA fill_color, Gdk.Rectangle original_size = null, Gdk.Rectangle requested_size = {}) {
        QSvgRenderer svg_renderer;

        if (!svg_renderer.on_signal_load (source_svg_path)) {
            GLib.warning ("Could no load initial SVG image.");
            return {};
        }

        const var req_size = requested_size.is_valid ? requested_size : svg_renderer.default_size ();

        if (original_size != null) {
            *original_size = svg_renderer.default_size ();
        }

        // render source image
        Gtk.Image svg_image = new Gtk.Image (req_size, Gtk.Image.FormatARGB32); {
            QPainter svg_image_painter = new QPainter (svg_image);
            svg_image.fill (Qt.GlobalColor.transparent);
            svg_renderer.render (svg_image_painter);
        }

        // draw target image with custom fill_color
        Gtk.Image image = new Gtk.Image (req_size, Gtk.Image.FormatARGB32);
        image.fill (Gdk.RGBA (fill_color)); {
            QPainter image_painter = new QPainter (image);
            image_painter.composition_mode (QPainter.Composition_mode_Destination_in);
            image_painter.draw_image (0, 0, svg_image);
        }

        return image;
    }

} // class IconUtils

} // namespace Ui
} // namespace Occ
