/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

This library is free software; you can redistribute it and
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later versi

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GN
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301  USA
***********************************************************/

// #include <QFrame>


/***********************************************************
@class KMessageWidget kmessagewidget.h KMessageWidget

@short A widget to provide feedback or propose opportunistic inte

KMessageWidget can be used to provide inline positive or negative
feedback, or to implement opportunistic interactions.

As a feedback widget, KMessageWidget provides a less intrusive alternative
to "OK Only" message boxes. If you want to avoid a modal KMe
consider using KMessageWidget instead.

Examples of KMessageWidget look as follows, all of them having an icon
with set_icon (), and the first three show a close button:

\image html kmessagewidget.png "KMessageWidget

<b>Negative feedback</b>

The KMessageWidget can be used as a sec
first indicator is usually the fact the action the user expected to hap
did not happen.

Example : User fills a form, clicks "Submit".

@li Expected feedback : form closes
@li First indicator of failure : form stays there
@li Second indicator of fai
form, explaining the error condition

When used to provide neg
close to its context. In the ca
form entries.

KMessageWidget should get ins
be reserved for it, otherwise it becomes
KMessageWidget should also not appear as an overlay
access to elements the user needs t

<b>Positive feedback</b>

KMessageWidget can be used for
overused. It is often enough to provide feedback by simply showin
results of an action.

Examples of acceptable uses:

@li Confirm success of "critical" transactions
@li Indicate completion of background tasks

Example of unadapted uses:

@li Indicate successful saving of a
@li Indicate a file has been successfully removed

<b>Opportunistic interaction</b>

Opportunistic interaction is the situation where the application
the user an action he could be interested in perform, either based on a
action the user just triggered or an event which the application noticed.

Example of acceptable uses:

@li A browser can propose remembering a recently entered password
@li A music collection can propose ripping a CD which just got inserted
@li A chat application may notify the user a "special friend" just connected

@author Aurélien Gâteau <agateau@kde.org>
@since 4.7
***********************************************************/
class KMessageWidget : QFrame {

    Q_PROPERTY (string text READ text WRITE set_text)
    Q_PROPERTY (bool word_wrap READ word_wrap WRITE set_word_wrap)
    Q_PROPERTY (bool close_button_visible READ is_close_button_visible WRITE set_close_button_visible)
    Q_PROPERTY (Message_type message_type READ message_type WRITE set_message_type)
    Q_PROPERTY (QIcon icon READ icon WRITE set_icon)

    /***********************************************************
    Available message types.
    The background colors are chosen depending on the message type.
    ***********************************************************/
    public enum Message_type {
        Positive,
        Information,
        Warning,
        Error
    };

    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent.
    ***********************************************************/
    public KMessageWidget (Gtk.Widget *parent = nullptr);

    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent and
    contents @p text.
    ***********************************************************/
    public KMessageWidget (string &text, Gtk.Widget *parent = nullptr);

    /***********************************************************
    Destructor.
    ***********************************************************/
    public ~KMessageWidget () override;

    /***********************************************************
    Get the text of this message widget.
    @see set_text ()
    ***********************************************************/
    public string text ();

    /***********************************************************
    Check whether word wrap is enabled.
    
    If word wrap is enabled, the message widget wraps the displayed tex
    as required to the available wi
    avoid breaking widget layouts.

    @see set_word_wrap ()
    ***********************************************************/
    public bool word_wrap ();

    /***********************************************************
    Check whether the close button is visible.
    
    @see set_close_button_visible ()
    ***********************************************************/
    public bool is_close_button_visible ();

    /***********************************************************
    Get the type of this message.
    By default, the type is set to KMessageWidget.Information.
    
    @see KMessageWidget.Message_type, set_message_type ()
    ***********************************************************/
    public Message_type message_type ();

    /***********************************************************
    Add @p action to the message widget.
    For each action a button is added to the message widget in the
    order the actions were added.
    
    @param action the action to add
    @see remove_action (), Gtk.Widget.actions ()
    ***********************************************************/
    public void add_action (QAction *action);

    /***********************************************************
    Remove @p action from the message widget.
    
    @param action the action to remove
    @see KMessageWidget.Message_type, add_action (), set_message_type ()
    ***********************************************************/
    public void remove_action (QAction *action);

    /***********************************************************
    Returns the preferred size of the message widget.
    ***********************************************************/
    public QSize size_hint () const override;

    /***********************************************************
    Returns the minimum size of the message widget.
    ***********************************************************/
    public QSize minimum_size_hint () const override;

    /***********************************************************
    Returns the required height for @p width.
    @param width the width in pixels
    ***********************************************************/
    public int height_for_width (int width) const override;

    /***********************************************************
    The icon shown on the left of the text. By default, no icon is shown.
    @since 4.11
    ***********************************************************/
    public QIcon icon ();

    /***********************************************************
    Check whether the hide animation started by calling animated_hide ()
    is still running. If animations are disabled, this function always
    returns @e false.
    
    @see animated_hide (), hide_animation_finished ()
    @since 5.0
    ***********************************************************/
    public bool is_hide_animation_running ();

    /***********************************************************
    Check whether the show animation started by calling animated_show ()
    is still running. If animations are disabled, this function always
    returns @e false.
    
    @see animated_show (), show_animation_finished ()
    @since 5.0
    ***********************************************************/
    public bool is_show_animation_running ();

public slots:
    /***********************************************************
    Set the text of the message widget to @p text.
    If the message widget is already visible, the text changes on the fly.
    
    @param text the text to display, rich text is allowed
    @see text ()
    ***********************************************************/
    void set_text (string &text);

    /***********************************************************
    Set word wrap to @p word_wrap. If word wrap is enabled, the text ()
    of the message widget is wrapped to fit the available width.
    If word wrap is disabled, the message widget's minimum size is
    such that the entire text fits.
    
    @param word_wrap disable/enable word wrap
    @see word_wrap ()
    ***********************************************************/
    void set_word_wrap (bool word_wrap);

    /***********************************************************
    Set the visibility of the close button. If @p visible is @e true,
    a close button is shown that calls animated_hide () if clicked.
    
    @see close_button_visible (), animated_hide ()
    ***********************************************************/
    void set_close_button_visible (bool visible);

    /***********************************************************
    Set the message type to @p type.
    By default, the message type is set to KMessageWidget.Information.
    Appropriate colors are chosen to mimic the appearance of Kirigami's
    Inline_message.
    
    @see message_type (), KMessageWidget.Message_type
    ***********************************************************/
    void set_message_type (KMessageWidget.Message_type type);

    /***********************************************************
    Show the widget using an animation.
    ***********************************************************/
    void animated_show ();

    /***********************************************************
    Hide the widget using an animation.
    ***********************************************************/
    void animated_hide ();

    /***********************************************************
    Define an icon to be shown on the left of the text
    @since 4.11
    ***********************************************************/
    void set_icon (QIcon &icon);

signals:
    /***********************************************************
    This signal is emitted when the user clicks a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.link_activated ()
    @since 4.10
    ***********************************************************/
    void link_activated (string &contents);

    /***********************************************************
    This signal is emitted when the user hovers over a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.link_hovered ()
    @since 4.11
    ***********************************************************/
    void link_hovered (string &contents);

    /***********************************************************
    This signal is emitted when the hide animation is finished, started by
    calling animated_hide (). If animations are disabled, this signal is
    emitted immediately after the message widget got hidden.
    
    @note This signal is @e not emitted if the widget was hidden by
          calling hide (), so th
          with animated_h
    
    @see animated_hide ()
    @since 5.0
    ***********************************************************/
    void hide_animation_finished ();

    /***********************************************************
    This signal is emitted when the show animation is finished, started by
    calling animated_show (). If animations are disabled, this signal is
    emitted immediately after the message widget got shown.
    
    @note This signal is @e not emitted if the widget was shown by
          calling show (), so th
          with animated_s
    
    @see animated_show ()
    @since 5.0
    ***********************************************************/
    void show_animation_finished ();

protected:
    void paint_event (QPaint_event *event) override;

    bool event (QEvent *event) override;

    void resize_event (QResizeEvent *event) override;

private:
    KMessageWidgetPrivate *const d;
    friend class KMessageWidgetPrivate;

    Q_PRIVATE_SLOT (d, void slot_time_line_changed (qreal))
    Q_PRIVATE_SLOT (d, void slot_time_line_finished ())
};










/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QAction>
// #include <QApplication>
// #include <QEvent>
// #include <QGrid_layout>
// #include <QHBox_layout>
// #include <QLabel>
// #include <QPainter>
// #include <QShow_event>
// #include <QTime_line>
// #include <QToolButton>
// #include <QStyle>

//---------------------------------------------------------------------
// KMessageWidgetPrivate
//---------------------------------------------------------------------
class KMessageWidgetPrivate {
    public void init (KMessageWidget *);
    
    public KMessageWidget *q;
    public QFrame *content = nullptr;
    public QLabel *icon_label = nullptr;
    public QLabel *text_label = nullptr;
    public QToolButton *close_button = nullptr;
    public QTime_line *time_line = nullptr;
    public QIcon icon;
    public bool ignore_show_event_doing_animated_show = false;

    public KMessageWidget.Message_type message_type;
    public bool word_wrap;
    public QList<QToolButton> buttons;
    public QPixmap content_snap_shot;

    public void create_layout ();
    public void apply_style_sheet ();
    public void update_snap_shot ();
    public void update_layout ();
    public void slot_time_line_changed (qreal);
    public void slot_time_line_finished ();

    public int best_content_height ();
};
    
    void KMessageWidgetPrivate.init (KMessageWidget *q_ptr) {
        q = q_ptr;
    
        q.set_size_policy (QSize_policy.Minimum, QSize_policy.Fixed);
    
        // Note : when changing the value 500, also update KMessage_widget_test
        time_line = new QTime_line (500, q);
        GLib.Object.connect (time_line, SIGNAL (value_changed (qreal)), q, SLOT (slot_time_line_changed (qreal)));
        GLib.Object.connect (time_line, SIGNAL (finished ()), q, SLOT (slot_time_line_finished ()));
    
        content = new QFrame (q);
        content.set_object_name (QStringLiteral ("content_widget"));
        content.set_size_policy (QSize_policy.Expanding, QSize_policy.Fixed);
    
        word_wrap = false;
    
        icon_label = new QLabel (content);
        icon_label.set_size_policy (QSize_policy.Fixed, QSize_policy.Fixed);
        icon_label.hide ();
    
        text_label = new QLabel (content);
        text_label.set_size_policy (QSize_policy.Expanding, QSize_policy.Fixed);
        text_label.set_text_interaction_flags (Qt.Text_browser_interaction);
        GLib.Object.connect (text_label, &QLabel.link_activated, q, &KMessageWidget.link_activated);
        GLib.Object.connect (text_label, &QLabel.link_hovered, q, &KMessageWidget.link_hovered);
    
        auto *close_action = new QAction (q);
        close_action.set_text (KMessageWidget.tr ("&Close"));
        close_action.set_tool_tip (KMessageWidget.tr ("Close message"));
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
    
        Q_FOREACH (QAction *action, q.actions ()) {
            auto *button = new QToolButton (content);
            button.set_default_action (action);
            button.set_tool_button_style (Qt.Tool_button_text_beside_icon);
            buttons.append (button);
        }
    
        // Auto_raise reduces visual clutter, but we don't want to turn it on if
        // there are other buttons, otherwise the close button will look different
        // from the others.
        close_button.set_auto_raise (buttons.is_empty ());
    
        if (word_wrap) {
            auto *layout = new QGrid_layout (content);
            // Set alignment to make sure icon does not move down if text wraps
            layout.add_widget (icon_label, 0, 0, 1, 1, Qt.Align_hCenter | Qt.Align_top);
            layout.add_widget (text_label, 0, 1);
    
            if (buttons.is_empty ()) {
                // Use top-vertical alignment like the icon does.
                layout.add_widget (close_button, 0, 2, 1, 1, Qt.Align_hCenter | Qt.Align_top);
            } else {
                // Use an additional layout in row 1 for the buttons.
                auto *button_layout = new QHBox_layout;
                button_layout.add_stretch ();
                Q_FOREACH (QToolButton *button, buttons) {
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
            auto *layout = new QHBox_layout (content);
            layout.add_widget (icon_label);
            layout.add_widget (text_label);
    
            for (QToolButton *button : q_as_const (buttons)) {
                layout.add_widget (button);
            }
    
            layout.add_widget (close_button);
        };
    
        if (q.is_visible ()) {
            q.set_fixed_height (content.size_hint ().height ());
        }
        q.update_geometry ();
    }
    
    void KMessageWidgetPrivate.apply_style_sheet () {
        QColor bg_base_color;
    
        // We have to hardcode colors here because KWidgets_addons is a tier 1 framework
        // and therefore can't depend on any other KDE Frameworks
        // The following RGB color values come from the "default" scheme in kcolorscheme.cpp
        switch (message_type) {
        case KMessageWidget.Positive:
            bg_base_color.set_rgb (39, 174,  96); // Window : Foreground_positive
            break;
        case KMessageWidget.Information:
            bg_base_color.set_rgb (61, 174, 233); // Window : Foreground_active
            break;
        case KMessageWidget.Warning:
            bg_base_color.set_rgb (246, 116, 0); // Window : Foreground_neutral
            break;
        case KMessageWidget.Error:
            bg_base_color.set_rgb (218, 68, 83); // Window : Foreground_negative
            break;
        }
        const qreal bg_base_color_alpha = 0.2;
        bg_base_color.set_alpha_f (bg_base_color_alpha);
    
        const QPalette palette = QGuiApplication.palette ();
        const QColor window_color = palette.window ().color ();
        const QColor text_color = palette.text ().color ();
        const QColor border = bg_base_color;
    
        // Generate a final background color from overlaying bg_base_color over window_color
        const int new_red = q_round (bg_base_color.red () * bg_base_color_alpha) + q_round (window_color.red () * (1 - bg_base_color_alpha));
        const int new_green = q_round (bg_base_color.green () * bg_base_color_alpha) + q_round (window_color.green () * (1 - bg_base_color_alpha));
        const int new_blue = q_round (bg_base_color.blue () * bg_base_color_alpha) + q_round (window_color.blue () * (1 - bg_base_color_alpha));
    
        const QColor bg_final_color = QColor (new_red, new_green, new_blue);
    
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
            // Default_frame_width returns the size of the external margin + border width. We know our border is 1px, so we subtract this from the frame normal QStyle Frame_width to get our margin
            .arg (q.style ().pixel_metric (QStyle.PM_Default_frame_width, nullptr, q) - 1)
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
        content.render (&content_snap_shot, QPoint (), QRegion (), Gtk.Widget.Draw_children);
    }
    
    void KMessageWidgetPrivate.slot_time_line_changed (qreal value) {
        q.set_fixed_height (q_min (q_round (value * 2.0), 1) * content.height ());
        q.update ();
    }
    
    void KMessageWidgetPrivate.slot_time_line_finished () {
        if (time_line.direction () == QTime_line.Forward) {
            // Show
            // We set the whole geometry here, because it may be wrong if a
            // KMessageWidget is shown right when the toplevel window is created.
            content.set_geometry (0, 0, q.width (), best_content_height ());
    
            // notify about finished animation
            emit q.show_animation_finished ();
        } else {
            // hide and notify about finished animation
            q.hide ();
            emit q.hide_animation_finished ();
        }
    }
    
    int KMessageWidgetPrivate.best_content_height () {
        int height = content.height_for_width (q.width ());
        if (height == -1) {
            height = content.size_hint ().height ();
        }
        return height;
    }
    
    //---------------------------------------------------------------------
    // KMessageWidget
    //---------------------------------------------------------------------
    KMessageWidget.KMessageWidget (Gtk.Widget *parent)
        : QFrame (parent)
        , d (new KMessageWidgetPrivate) {
        d.init (this);
    }
    
    KMessageWidget.KMessageWidget (string &text, Gtk.Widget *parent)
        : QFrame (parent)
        , d (new KMessageWidgetPrivate) {
        d.init (this);
        set_text (text);
    }
    
    KMessageWidget.~KMessageWidget () {
        delete d;
    }
    
    string KMessageWidget.text () {
        return d.text_label.text ();
    }
    
    void KMessageWidget.set_text (string &text) {
        d.text_label.set_text (text);
        update_geometry ();
    }
    
    KMessageWidget.Message_type KMessageWidget.message_type () {
        return d.message_type;
    }
    
    void KMessageWidget.set_message_type (KMessageWidget.Message_type type) {
        d.message_type = type;
        d.apply_style_sheet ();
    }
    
    QSize KMessageWidget.size_hint () {
        ensure_polished ();
        return d.content.size_hint ();
    }
    
    QSize KMessageWidget.minimum_size_hint () {
        ensure_polished ();
        return d.content.minimum_size_hint ();
    }
    
    bool KMessageWidget.event (QEvent *event) {
        if (event.type () == QEvent.Polish && !d.content.layout ()) {
            d.create_layout ();
        } else if (event.type () == QEvent.PaletteChange) {
            d.apply_style_sheet ();
        } else if (event.type () == QEvent.Show && !d.ignore_show_event_doing_animated_show) {
            if ( (height () != d.content.height ()) || (d.content.pos ().y () != 0)) {
                d.content.move (0, 0);
                set_fixed_height (d.content.height ());
            }
        }
        return QFrame.event (event);
    }
    
    void KMessageWidget.resize_event (QResizeEvent *event) {
        QFrame.resize_event (event);
    
        if (d.time_line.state () == QTime_line.Not_running) {
            d.content.resize (width (), d.best_content_height ());
        }
    }
    
    int KMessageWidget.height_for_width (int width) {
        ensure_polished ();
        return d.content.height_for_width (width);
    }
    
    void KMessageWidget.paint_event (QPaint_event *event) {
        QFrame.paint_event (event);
        if (d.time_line.state () == QTime_line.Running) {
            QPainter painter (this);
            painter.set_opacity (d.time_line.current_value () * d.time_line.current_value ());
            painter.draw_pixmap (0, 0, d.content_snap_shot);
        }
    }
    
    bool KMessageWidget.word_wrap () {
        return d.word_wrap;
    }
    
    void KMessageWidget.set_word_wrap (bool word_wrap) {
        d.word_wrap = word_wrap;
        d.text_label.set_word_wrap (word_wrap);
        QSize_policy policy = size_policy ();
        policy.set_height_for_width (word_wrap);
        set_size_policy (policy);
        d.update_layout ();
        // Without this, when user does word_wrap . !word_wrap . word_wrap, a minimum
        // height is set, causing the widget to be too high.
        // Mostly visible in test programs.
        if (word_wrap) {
            set_minimum_height (0);
        }
    }
    
    bool KMessageWidget.is_close_button_visible () {
        return d.close_button.is_visible ();
    }
    
    void KMessageWidget.set_close_button_visible (bool show) {
        d.close_button.set_visible (show);
        update_geometry ();
    }
    
    void KMessageWidget.add_action (QAction *action) {
        QFrame.add_action (action);
        d.update_layout ();
    }
    
    void KMessageWidget.remove_action (QAction *action) {
        QFrame.remove_action (action);
        d.update_layout ();
    }
    
    void KMessageWidget.animated_show () {
        // Test before style_hint, as there might have been a style change while animation was running
        if (is_hide_animation_running ()) {
            d.time_line.stop ();
            emit hide_animation_finished ();
        }
    
        if (!style ().style_hint (QStyle.SH_Widget_Animate, nullptr, this)
         || (parent_widget () && !parent_widget ().is_visible ())) {
            show ();
            emit show_animation_finished ();
            return;
        }
    
        if (is_visible () && (d.time_line.state () == QTime_line.Not_running) && (height () == d.best_content_height ()) && (d.content.pos ().y () == 0)) {
            emit show_animation_finished ();
            return;
        }
    
        d.ignore_show_event_doing_animated_show = true;
        show ();
        d.ignore_show_event_doing_animated_show = false;
        set_fixed_height (0);
        int wanted_height = d.best_content_height ();
        d.content.set_geometry (0, -wanted_height, width (), wanted_height);
    
        d.update_snap_shot ();
    
        d.time_line.set_direction (QTime_line.Forward);
        if (d.time_line.state () == QTime_line.Not_running) {
            d.time_line.start ();
        }
    }
    
    void KMessageWidget.animated_hide () {
        // test this before is_visible, as animated_show might have been called directly before,
        // so the first timeline event is not yet done and the widget is still hidden
        // And before style_hint, as there might have been a style change while animation was running
        if (is_show_animation_running ()) {
            d.time_line.stop ();
            emit show_animation_finished ();
        }
    
        if (!style ().style_hint (QStyle.SH_Widget_Animate, nullptr, this)) {
            hide ();
            emit hide_animation_finished ();
            return;
        }
    
        if (!is_visible ()) {
            // explicitly hide it, so it stays hidden in case it is only not visible due to the parents
            hide ();
            emit hide_animation_finished ();
            return;
        }
    
        d.content.move (0, -d.content.height ());
        d.update_snap_shot ();
    
        d.time_line.set_direction (QTime_line.Backward);
        if (d.time_line.state () == QTime_line.Not_running) {
            d.time_line.start ();
        }
    }
    
    bool KMessageWidget.is_hide_animation_running () {
        return (d.time_line.direction () == QTime_line.Backward)
            && (d.time_line.state () == QTime_line.Running);
    }
    
    bool KMessageWidget.is_show_animation_running () {
        return (d.time_line.direction () == QTime_line.Forward)
            && (d.time_line.state () == QTime_line.Running);
    }
    
    QIcon KMessageWidget.icon () {
        return d.icon;
    }
    
    void KMessageWidget.set_icon (QIcon &icon) {
        d.icon = icon;
        if (d.icon.is_null ()) {
            d.icon_label.hide ();
        } else {
            const int size = style ().pixel_metric (QStyle.PM_Tool_bar_icon_size);
            d.icon_label.set_pixmap (d.icon.pixmap (size));
            d.icon_label.show ();
        }
    }
    
    #include "moc_kmessagewidget.cpp"
    
    