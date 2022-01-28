/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
Based on Qt sourcecode:
  qt5/qtbase/src/widgets/dialogs/qwizard

https://code.qt.io/c

Original license:

Copyright (C) 2016 The
Contact : https://www.qt

This file is part of the Qt_widgets module of the Qt Toolkit.

$QT_BEGIN_LICENSE:LGPL$
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

** $QT_END_LICENSE$
****************************************************************************/


/***********************************************************
Based on Qt sourcecode:
  qt5/qtbase/src/widgets/dialogs/qwizard

https://code.qt.io/c

Original license:

Copyright (C) 2016 The
Contact : https://www.qt

This file is part of the Qt_widgets module of the Qt Toolkit.

$QT_BEGIN_LICENSE:LGPL$
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

** $QT_END_LICENSE$
****************************************************************************/

// #include <Gtk.Widget>
// #include <QVBoxLayout>
// #include <QLabel>

// #include <QPainter>
// #include <QStyle>
// #include <QGuiApplication>


namespace Occ {

class HeaderBanner : Gtk.Widget {

    public HeaderBanner (Gtk.Widget parent = nullptr);

    public void setup (string title, QPixmap &logo, QPixmap &banner,
               const Qt.Text_format title_format, string style_sheet);


    protected void paint_event (QPaint_event event) override;


    private QLabel title_label;
    private QLabel logo_label;
    private QGrid_layout layout;
    private QPixmap banner_pixmap;
};



    // These fudge terms were needed a few places to obtain pixel-perfect results
    const int Gap_between_logo_and_right_edge = 5;
    const int Modern_header_top_margin = 2;

    HeaderBanner.HeaderBanner (Gtk.Widget parent)
        : Gtk.Widget (parent) {
        set_size_policy (QSize_policy.Expanding, QSize_policy.Fixed);
        set_background_role (QPalette.Base);
        title_label = new QLabel (this);
        title_label.set_background_role (QPalette.Base);
        logo_label = new QLabel (this);
        QFont font = title_label.font ();
        font.set_bold (true);
        title_label.set_font (font);
        layout = new QGrid_layout (this);
        layout.set_contents_margins (QMargins ());
        layout.set_spacing (0);
        layout.set_row_minimum_height (3, 1);
        layout.set_row_stretch (4, 1);
        layout.set_column_stretch (2, 1);
        layout.set_column_minimum_width (4, 2 * Gap_between_logo_and_right_edge);
        layout.set_column_minimum_width (6, Gap_between_logo_and_right_edge);
        layout.add_widget (title_label, 1, 1, 5, 1);
        layout.add_widget (logo_label, 1, 5, 5, 1);
    }

    void HeaderBanner.setup (string title, QPixmap &logo, QPixmap &banner,
                             const Qt.Text_format title_format, string style_sheet) {
        QStyle style = parent_widget ().style ();
        //const int layout_horizontal_spacing = style.pixel_metric (QStyle.PM_Layout_horizontal_spacing);
        int top_level_margin_left = style.pixel_metric (QStyle.PM_Layout_left_margin, nullptr, parent_widget ());
        int top_level_margin_right = style.pixel_metric (QStyle.PM_Layout_right_margin, nullptr, parent_widget ());
        int top_level_margin_top = style.pixel_metric (QStyle.PM_Layout_top_margin, nullptr, parent_widget ());
        //int top_level_margin_bottom = style.pixel_metric (QStyle.PM_Layout_bottom_margin, 0, parent_widget ());

        layout.set_row_minimum_height (0, Modern_header_top_margin);
        layout.set_row_minimum_height (1, top_level_margin_top - Modern_header_top_margin - 1);
        layout.set_row_minimum_height (6, 3);
        int min_column_width0 = top_level_margin_left + top_level_margin_right;
        int min_column_width1 = top_level_margin_left + top_level_margin_right + 1;
        layout.set_column_minimum_width (0, min_column_width0);
        layout.set_column_minimum_width (1, min_column_width1);
        title_label.set_text_format (title_format);
        title_label.on_set_text (title);
        if (!style_sheet.is_empty ())
            title_label.set_style_sheet (style_sheet);
        logo_label.set_pixmap (logo);
        banner_pixmap = banner;
        if (banner_pixmap.is_null ()) {
            QSize size = layout.total_minimum_size ();
            set_minimum_size (size);
            set_maximum_size (QWIDGETSIZE_MAX, size.height ());
        } else {
            set_fixed_height (banner.height () + 2);
        }
        update_geometry ();
    }

    void HeaderBanner.paint_event (QPaint_event * /* event */) {
        QPainter painter (this);
        painter.draw_pixmap (0, 0, width (), banner_pixmap.height (), banner_pixmap);
        int x = width () - 2;
        int y = height () - 2;
        const QPalette &pal = QGuiApplication.palette ();
        painter.set_pen (pal.mid ().color ());
        painter.draw_line (0, y, x, y);
        painter.set_pen (pal.base ().color ());
        painter.draw_point (x + 1, y);
        painter.draw_line (0, y + 1, x + 1, y + 1);
    }

    } // namespace Occ
    