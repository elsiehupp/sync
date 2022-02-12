
/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <QAction>
//  #include <QApplication>
//  #include <QEvent>
//  #include <QGridLayout>
//  #include <QHBoxLayout>
//  #include <QLabel>
//  #include <QPainter>
//  #include <QShowEvent>
//  #include <QTimeLine>
//  #include <QToolButton>
//  #include <QStyle>

//---------------------------------------------------------------------
// KMessageWidgetPrivate
//---------------------------------------------------------------------
class KMessageWidgetPrivate {
    public void on_init (KMessageWidget *);

    /***********************************************************
    ***********************************************************/
    public KMessageWidget q;
    public QFrame content = null;
    public QLabel icon_label = null;
    public QLabel text_label = null;
    public QToolButton close_button = null;
    public QTimeLine time_line = null;
    public QIcon icon;
    public bool ignore_show_event_doing_animated_show = false;

    /***********************************************************
    ***********************************************************/
    public KMessageWidget.MessageType message_type;
    public bool word_wrap;
    public GLib.List<QToolButton> buttons;
    public QPixmap content_snap_shot;

    /***********************************************************
    ***********************************************************/
    public void create_layout ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void update_snap_shot (

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_time_line_changed (qreal);


    public void on_time_line_finished ();

    public int best_content_height ();
}

    void KMessageWidgetPrivate.on_init (KMessageWidget q_ptr) {
        q = q_ptr;

        q.set_size_policy (QSizePolicy.Minimum, QSizePolicy.Fixed);

        // Note: when changing the value 500, also update KMessageWidgetTest
        time_line = new QTimeLine (500, q);
        GLib.Object.connect (time_line, SIGNAL (value_changed (qreal)), q, SLOT (on_time_line_changed (qreal)));
        GLib.Object.connect (time_line, SIGNAL (on_finished ()), q, SLOT (on_time_line_finished ()));

        content = new QFrame (q);
        content.set_object_name ("content_widget");
        content.set_size_policy (QSizePolicy.Expanding, QSizePolicy.Fixed);

        word_wrap = false;

        icon_label = new QLabel (content);
        icon_label.set_size_policy (QSizePolicy.Fixed, QSizePolicy.Fixed);
        icon_label.hide ();

        text_label = new QLabel (content);
        text_label.set_size_policy (QSizePolicy.Expanding, QSizePolicy.Fixed);
        text_label.set_text_interaction_flags (Qt.TextBrowserInteraction);
        GLib.Object.connect (text_label, &QLabel.link_activated, q, &KMessageWidget.link_activated);
        GLib.Object.connect (text_label, &QLabel.link_hovered, q, &KMessageWidget.link_hovered);

        var close_action = new QAction (q);
        close_action.on_set_text (KMessageWidget._("&Close"));
        close_action.set_tool_tip (KMessageWidget._("Close message"));
        close_action.set_icon (QIcon (":/client/theme/close.svg")); // ivan : NC customization

        GLib.Object.connect (close_action, &QAction.triggered, q, &KMessageWidget.animated_hide);

        close_button = new QToolButton (content);
        close_button.set_auto_raise (true);
        close_button.set_default_action (close_action);

        q.set_message_type (KMessageWidget.Information);
    }

    void KMessageWidgetPrivate.create_layout () {
        delete content.layout ();

        content.resize (q.size ());

        q_delete_all (buttons);
        buttons.clear ();

        Q_FOREACH (QAction action, q.actions ()) {
            var button = new QToolButton (content);
            button.set_default_action (action);
            button.set_tool_button_style (Qt.ToolButtonTextBesideIcon);
            buttons.append (button);
        }

        // AutoRaise reduces visual clutter, but we don't want to turn it on if
        // there are other buttons, otherwise the close button will look different
        // from the others.
        close_button.set_auto_raise (buttons.is_empty ());

        if (word_wrap) {
            var layout = new QGridLayout (content);
            // Set alignment to make sure icon does not move down if text wraps
            layout.add_widget (icon_label, 0, 0, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            layout.add_widget (text_label, 0, 1);

            if (buttons.is_empty ()) {
                // Use top-vertical alignment like the icon does.
                layout.add_widget (close_button, 0, 2, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            } else {
                // Use an additional layout in row 1 for the buttons.
                var button_layout = new QHBoxLayout;
                button_layout.add_stretch ();
                Q_FOREACH (QToolButton button, buttons) {
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

            for (QToolButton button : q_as_const (buttons)) {
                layout.add_widget (button);
            }

            layout.add_widget (close_button);
        }

        if (q.is_visible ()) {
            q.set_fixed_height (content.size_hint ().height ());
        }
        q.update_geometry ();
    }

    void KMessageWidgetPrivate.apply_style_sheet () {
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
        const qreal bg_base_color_alpha = 0.2;
        bg_base_color.set_alpha_f (bg_base_color_alpha);

        const QPalette palette = QGuiApplication.palette ();
        const Gtk.Color window_color = palette.window ().color ();
        const Gtk.Color text_color = palette.text ().color ();
        const Gtk.Color border = bg_base_color;

        // Generate a final background color from overlaying bg_base_color over window_color
        const int new_red = q_round (bg_base_color.red () * bg_base_color_alpha) + q_round (window_color.red () * (1 - bg_base_color_alpha));
        const int new_green = q_round (bg_base_color.green () * bg_base_color_alpha) + q_round (window_color.green () * (1 - bg_base_color_alpha));
        const int new_blue = q_round (bg_base_color.blue () * bg_base_color_alpha) + q_round (window_color.blue () * (1 - bg_base_color_alpha));

        const Gtk.Color bg_final_color = Gtk.Color (new_red, new_green, new_blue);

        content.set_style_sheet (
            string.from_latin1 (".QFrame {"
                                  "background-color : %1;"
                                  "border-radius : 4px;"
                                  "border : 2px solid %2;"
                                  "margin : %3px;"
                                  "}"
                                  ".QLabel { color : %4; }"
                                 )
            .arg (bg_final_color.name ())
            .arg (border.name ())
            // DefaultFrameWidth returns the size of the external margin + border width. We know our border is 1px, so we subtract this from the frame normal QStyle FrameWidth to get our margin
            .arg (q.style ().pixel_metric (QStyle.PM_DefaultFrameWidth, null, q) - 1)
            .arg (text_color.name ())
        );
    }

    void KMessageWidgetPrivate.update_layout () {
        if (content.layout ()) {
            create_layout ();
        }
    }

    void KMessageWidgetPrivate.update_snap_shot () {
        // Attention : update_snap_shot calls Gtk.Widget.render (), which causes the whole
        // window layouts to be activated. Calling this method from resize_event ()
        // can lead to infinite recursion, see:
        // https://bugs.kde.org/show_bug.cgi?id=311336
        content_snap_shot = QPixmap (content.size () * q.device_pixel_ratio ());
        content_snap_shot.set_device_pixel_ratio (q.device_pixel_ratio ());
        content_snap_shot.fill (Qt.transparent);
        content.render (&content_snap_shot, QPoint (), QRegion (), Gtk.Widget.DrawChildren);
    }

    void KMessageWidgetPrivate.on_time_line_changed (qreal value) {
        q.set_fixed_height (q_min (q_round (value * 2.0), 1) * content.height ());
        q.update ();
    }

    void KMessageWidgetPrivate.on_time_line_finished () {
        if (time_line.direction () == QTimeLine.Forward) {
            // Show
            // We set the whole geometry here, because it may be wrong if a
            // KMessageWidget is shown right when the toplevel window is created.
            content.set_geometry (0, 0, q.width (), best_content_height ());

            // notify about on_finished animation
            /* emit */ q.show_animation_finished ();
        } else {
            // hide and notify about on_finished animation
            q.hide ();
            /* emit */ q.hide_animation_finished ();
        }
    }

    int KMessageWidgetPrivate.best_content_height () {
        int height = content.height_for_width (q.width ());
        if (height == -1) {
            height = content.size_hint ().height ();
        }
        return height;
    }