/***********************************************************
@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/

/***********************************************************
Based on Qt sourcecode:
  qt5/qtbase/src/widgets/dialogs/qwizard

https://code.qt.io/c

Original license:

@author 2016 The
Contact : https://www.qt

This file is part of the Qt_widgets module of the Qt Toolkit.

$GLib.T_BEGIN_LICENSE:LGPL$
Commercial License Usage
Licensees holding valid commercial Qt licenses may use this file in
accordance with the commercial license
Software or, alternatively, in accordance with the terms contained in
a written agreement between you and The Qt Company. For licensing
and conditions see https://www.qt.io/terms-conditions. For further
information use the contact form at https://www.qt.io/contact-us.

GNU Lesser General Public License Usage
Alternatively, this file may be
General Public License version 3 as published by the Free Softw
Foundation and appearing in the file LICENSE.LGPL3 included in the
packaging of this file. Please review the following information to
ensure the GNU Lesser General Public License version 3 requiremen
will be met : https://www.gnu.org/licenses/lgpl-3.0.html.

GNU General Public License Usage
Alternatively, this file may be used under the terms o
General Public License version 2.0 or (at you
Public license version 3 or any later version approved by the KDE Free
Qt Foundation. The licenses are as published by the Free Software
Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
included in the packaging of this file. Please review the following
information to ensure the GNU General Public License requirements will
be met : https://www.gnu.org/licenses/gpl-2.0.html and
https://www.gnu.org/licenses/gpl-3.0.html.

** $GLib.T_END_LICENSE$
****************************************************************************/


/***********************************************************
Based on Qt sourcecode:
  qt5/qtbase/src/widgets/dialogs/qwizard

https://code.qt.io/c

Original license:

@author 2016 The
Contact : https://www.qt

This file is part of the Qt_widgets module of the Qt Toolkit.

$GLib.T_BEGIN_LICENSE:LGPL$
Commercial License Usage
Licensees holding valid commercial Qt licenses may use this file in
accordance with the commercial license
Software or, alternatively, in accordance with the terms contained in
a written agreement between you and The Qt Company. For licensing
and conditions see https://www.qt.io/terms-conditions. For further
information use the contact form at https://www.qt.io/contact-us.

GNU Lesser General Public License Usage
Alternatively, this file may be
General Public License version 3 as published by the Free Softw
Foundation and appearing in the file LICENSE.LGPL3 included in the
packaging of this file. Please review the following information to
ensure the GNU Lesser General Public License version 3 requiremen
will be met : https://www.gnu.org/licenses/lgpl-3.0.html.

GNU General Public License Usage
Alternatively, this file may be used under the terms o
General Public License version 2.0 or (at you
Public license version 3 or any later version approved by the KDE Free
Qt Foundation. The licenses are as published by the Free Software
Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
included in the packaging of this file. Please review the following
information to ensure the GNU General Public License requirements will
be met : https://www.gnu.org/licenses/gpl-2.0.html and
https://www.gnu.org/licenses/gpl-3.0.html.

** $GLib.T_END_LICENSE$
****************************************************************************/

//  #include <Gtk.Widget>
//  #include <GLib.Painte
//  #include <GLib.Style>
//  #include <GLib.Application>

namespace Occ {
namespace Ui {

public class HeaderBanner { //: Gtk.Widget {

//    /***********************************************************
//    These fudge terms were needed a few places to obtain
//    pixel-perfect results
//    ***********************************************************/
//    const int GAP_BETWEEN_LOGO_AND_RIGHT_EDGE = 5;

//    /***********************************************************
//    These fudge terms were needed a few places to obtain
//    pixel-perfect results
//    ***********************************************************/
//    const int MODERN_HEADER_TOP_MARGIN = 2;

//    /***********************************************************
//    ***********************************************************/
//    private Gtk.Label title_label;
//    private Gtk.Label logo_label;
//    private GLib.GridLayout layout;
//    private Gdk.Pixbuf banner_pixmap;

//    /***********************************************************
//    ***********************************************************/
//    public HeaderBanner (Gtk.Widget parent = new Gtk.Widget ()) {
//        base (parent);
//        size_policy (GLib.SizePolicy.Expanding, GLib.SizePolicy.Fixed);
//        background_role (Gtk.Palette.Base);
//        title_label = new Gtk.Label (this);
//        title_label.background_role (Gtk.Palette.Base);
//        logo_label = new Gtk.Label (this);
//        Cairo.FontFace font = title_label.font ();
//        font.bold (true);
//        title_label.font (font);
//        layout = new GLib.GridLayout (this);
//        layout.contents_margins (GLib.Margins ());
//        layout.spacing (0);
//        layout.row_minimum_height (3, 1);
//        layout.row_stretch (4, 1);
//        layout.column_stretch (2, 1);
//        layout.column_minimum_width (4, 2 * GAP_BETWEEN_LOGO_AND_RIGHT_EDGE);
//        layout.column_minimum_width (6, GAP_BETWEEN_LOGO_AND_RIGHT_EDGE);
//        layout.add_widget (title_label, 1, 1, 5, 1);
//        layout.add_widget (logo_label, 1, 5, 5, 1);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void setup (
//        string title,
//        Gdk.Pixbuf logo,
//        Gdk.Pixbuf banner,
//        GLib.TextFormat title_format,
//        string style_sheet) {
//        GLib.Style style = parent_widget ().this.style;
//        //  const int layout_horizontal_spacing = style.pixel_metric (GLib.Style.PM_Layout_horizontal_spacing);
//        int top_level_margin_left = style.pixel_metric (GLib.Style.PM_Layout_left_margin, null, parent_widget ());
//        int top_level_margin_right = style.pixel_metric (GLib.Style.PM_Layout_right_margin, null, parent_widget ());
//        int top_level_margin_top = style.pixel_metric (GLib.Style.PM_Layout_top_margin, null, parent_widget ());
//        //  int top_level_margin_bottom = style.pixel_metric (GLib.Style.PM_Layout_bottom_margin, 0, parent_widget ());

//        layout.row_minimum_height (0, MODERN_HEADER_TOP_MARGIN);
//        layout.row_minimum_height (1, top_level_margin_top - MODERN_HEADER_TOP_MARGIN - 1);
//        layout.row_minimum_height (6, 3);
//        int min_column_width0 = top_level_margin_left + top_level_margin_right;
//        int min_column_width1 = top_level_margin_left + top_level_margin_right + 1;
//        layout.column_minimum_width (0, min_column_width0);
//        layout.column_minimum_width (1, min_column_width1);
//        title_label.text_format (title_format);
//        title_label.on_signal_text (title);
//        if (style_sheet != "") {
//            title_label.style_sheet (style_sheet);
//        }
//        logo_label.pixmap (logo);
//        banner_pixmap = banner;
//        if (banner_pixmap == null) {
//            Gdk.Rectangle size = layout.total_minimum_size ();
//            minimum_size (size);
//            maximum_size (GLib.WIDGETSIZE_MAX, size.height ());
//        } else {
//            fixed_height (banner.height () + 2);
//        }
//        update_geometry ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected override void paint_event (GLib.PaintEvent event) {
//        GLib.Painter painter = new GLib.Painter (this);
//        painter.draw_pixmap (0, 0, width (), banner_pixmap.height (), banner_pixmap);
//        int x = width () - 2;
//        int y = height () - 2;
//        Gtk.Palette pal = GLib.Application.palette ();
//        painter.pen (pal.mid ().color ());
//        painter.draw_line (0, y, x, y);
//        painter.pen (pal.base ().color ());
//        painter.draw_point (x + 1, y);
//        painter.draw_line (0, y + 1, x + 1, y + 1);
//    }

} // class HeaderBanner

} // namespace Ui
} // namespace Occ
