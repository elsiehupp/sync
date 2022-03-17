
/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <QAction>
//  #include <Gtk.Application>
//  #include <QEvent>
//  #include <QGridLayout>
//  #include <QHBoxLayout>
//  #include <Gtk.Label>
//  #include <QPainter>
//  #include <QShowEvent>
//  #include <QTimeLine>
//  #include <QToolButton>
//  #include <QStyle>

/***********************************************************
KMessageWidgetPrivate
***********************************************************/
public class KMessageWidgetPrivate {

    /***********************************************************
    ***********************************************************/
    public KMessageWidget widget;
    public Gdk.Frame content = null;
    public Gtk.Label icon_label = null;
    public Gtk.Label text_label = null;
    public QToolButton close_button = null;
    public QTimeLine time_line = null;
    public Gtk.Icon icon;
    public bool ignore_show_event_doing_animated_show = false;

    /***********************************************************
    ***********************************************************/
    public KMessageWidget.MessageType message_type;
    public bool word_wrap;
    public GLib.List<QToolButton> buttons;
    public Gdk.Pixbuf content_snap_shot;

    /***********************************************************
    ***********************************************************/
    public void on_init (KMessageWidget widget) {
        widget.set_size_policy (QSizePolicy.Minimum, QSizePolicy.Fixed);

        // Note: when changing the value 500, also update KMessageWidgetTest
        time_line = new QTimeLine (500, widget);
        connect (
            time_line, value_changed (double),
            widget, on_time_line_changed (double)
        );
        connect (
            time_line, finished (),
            widget, on_time_line_finished ()
        );

        content = new Gdk.Frame (widget);
        content.set_object_name ("content_widget");
        content.set_size_policy (QSizePolicy.Expanding, QSizePolicy.Fixed);

        word_wrap = false;

        icon_label = new Gtk.Label (content);
        icon_label.set_size_policy (QSizePolicy.Fixed, QSizePolicy.Fixed);
        icon_label.hide ();

        text_label = new Gtk.Label (content);
        text_label.set_size_policy (QSizePolicy.Expanding, QSizePolicy.Fixed);
        text_label.set_text_interaction_flags (Qt.TextBrowserInteraction);
        connect (
            text_label, Gtk.Label.link_activated,
            widget, KMessageWidget.link_activated
        );
        connect (
            text_label, Gtk.Label.link_hovered,
            widget, KMessageWidget.link_hovered
        );

        var close_action = new QAction (widget);
        close_action.on_set_text (KMessageWidget._("&Close"));
        close_action.set_tool_tip (KMessageWidget._("Close message"));
        close_action.on_signal_set_icon (Gtk.Icon (":/client/theme/close.svg")); // ivan : NC customization

        connect (
            close_action, QAction.triggered,
            widget, KMessageWidget.on_signal_animated_hide
        );

        close_button = new QToolButton (content);
        close_button.set_auto_raise (true);
        close_button.set_default_action (close_action);

        widget.on_signal_set_message_type (KMessageWidget.Information);
    }


    /***********************************************************
    ***********************************************************/
    public void create_layout () {
        delete content.layout ();

        content.resize (widget.size ());

        q_delete_all (buttons);
        buttons.clear ();

        foreach (QAction action in widget.actions ()) {
            var button = new QToolButton (content);
            button.set_default_action (action);
            button.set_tool_button_style (Qt.ToolButtonTextBesideIcon);
            buttons.append (button);
        }

        // AutoRaise reduces visual clutter, but we don't want to turn it on if
        // there are other buttons, otherwise the close button will look different
        // from the others.
        close_button.set_auto_raise (buttons == "");

        if (word_wrap) {
            var layout = new QGridLayout (content);
            // Set alignment to make sure icon does not move down if text wraps
            layout.add_widget (icon_label, 0, 0, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            layout.add_widget (text_label, 0, 1);

            if (buttons == "") {
                // Use top-vertical alignment like the icon does.
                layout.add_widget (close_button, 0, 2, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            } else {
                // Use an additional layout in row 1 for the buttons.
                var button_layout = new QHBoxLayout ();
                button_layout.add_stretch ();
                foreach (QToolButton button in buttons) {
                    // For some reason, calling show () is necessary if wordwrap is true,
                    // otherwise the buttons do not show up. It is not needed if
                    // wordwrap is false.
                    button.show ();
                    button_layout.add_widget (button);
                }
                button_layout.add_widget (close_button);
                layout.add_item (button_layout, 1, 0, 1, 2);
            }
        } else {
            var layout = new QHBoxLayout (content);
            layout.add_widget (icon_label);
            layout.add_widget (text_label);

            foreach (QToolButton button in buttons) {
                layout.add_widget (button);
            }

            layout.add_widget (close_button);
        }

        if (widget.is_visible ()) {
            widget.set_fixed_height (content.size_hint ().height ());
        }
        widget.update_geometry ();
    }


    /***********************************************************
    ***********************************************************/
    public void apply_style_sheet () {
        Gtk.Color bg_base_color;

        // We have to hardcode colors here because KWidgetsAddons is a tier 1 framework
        // and therefore can't depend on any other KDE Frameworks
        // The following RGB color values come from the "default" scheme in kcolorscheme
        switch (message_type) {
        case KMessageWidget.Positive:
            bg_base_color.set_rgb (39, 174,  96); // Window : ForegroundPositive
            break;
        case KMessageWidget.Information:
            bg_base_color.set_rgb (61, 174, 233); // Window : ForegroundActive
            break;
        case KMessageWidget.Warning:
            bg_base_color.set_rgb (246, 116, 0); // Window : ForegroundNeutral
            break;
        case KMessageWidget.Error:
            bg_base_color.set_rgb (218, 68, 83); // Window : ForegroundNegative
            break;
        }
        const double bg_base_color_alpha = 0.2;
        bg_base_color.set_alpha_f (bg_base_color_alpha);

        const QPalette palette = Gtk.Application.palette ();
        const Gtk.Color window_color = palette.window ().color ();
        const Gtk.Color text_color = palette.text ().color ();
        const Gtk.Color border = bg_base_color;

        // Generate a final background color from overlaying bg_base_color over window_color
        const int new_red = q_round (bg_base_color.red () * bg_base_color_alpha) + q_round (window_color.red () * (1 - bg_base_color_alpha));
        const int new_green = q_round (bg_base_color.green () * bg_base_color_alpha) + q_round (window_color.green () * (1 - bg_base_color_alpha));
        const int new_blue = q_round (bg_base_color.blue () * bg_base_color_alpha) + q_round (window_color.blue () * (1 - bg_base_color_alpha));

        const Gtk.Color bg_final_color = Gtk.Color (new_red, new_green, new_blue);

        content.set_style_sheet (
            ".Gdk.Frame {"
            + "background-color : %1;".printf (bg_final_color.name ())
            + "border-radius : 4px;"
            + "border: 2px solid %2;".printf (border.name ())
            // DefaultFrameWidth returns the size of the external margin + border width. We know our border is 1px, so we subtract this from the frame normal QStyle FrameWidth to get our margin
            + "margin: %3px;".printf (widget.style ().pixel_metric (QStyle.PM_DefaultFrameWidth, null, widget) - 1)
            + "}"
            + ".Gtk.Label { color : %4; }".printf (text_color.name ())
        );
    }


    /***********************************************************
    ***********************************************************/
    public void update_layout () {
        if (content.layout ()) {
            create_layout ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void update_snap_shot () {
        // Attention : update_snap_shot calls Gtk.Widget.render (), which causes the whole
        // window layouts to be activated. Calling this method from resize_event ()
        // can lead to infinite recursion, see:
        // https://bugs.kde.org/show_bug.cgi?id=311336
        content_snap_shot = Gdk.Pixbuf (content.size () * widget.device_pixel_ratio ());
        content_snap_shot.set_device_pixel_ratio (widget.device_pixel_ratio ());
        content_snap_shot.fill (Qt.transparent);
        content.render (&content_snap_shot, QPoint (), QRegion (), Gtk.Widget.DrawChildren);
    }


    /***********************************************************
    ***********************************************************/
    public void on_time_line_changed (double value) {
        widget.set_fixed_height (q_min (q_round (value * 2.0), 1) * content.height ());
        widget.update ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_time_line_finished () {
        if (time_line.direction () == QTimeLine.Forward) {
            // Show
            // We set the whole geometry here, because it may be wrong if a
            // KMessageWidget is shown right when the toplevel window is created.
            content.set_geometry (0, 0, widget.width (), best_content_height ());

            // notify about on_finished animation
            /* emit */ widget.show_animation_finished ();
        } else {
            // hide and notify about on_finished animation
            widget.hide ();
            /* emit */ widget.hide_animation_finished ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public int best_content_height () {
        int height = content.height_for_width (widget.width ());
        if (height == -1) {
            height = content.size_hint ().height ();
        }
        return height;
    }

}
