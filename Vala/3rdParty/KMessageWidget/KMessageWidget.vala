/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #include <QFrame>


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

Example: User fills a form, clicks "Submit".

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

    //  Q_PROPERTY (string text READ text WRITE on_set_text)
    //  Q_PROPERTY (bool word_wrap READ word_wrap WRITE set_word_wrap)
    //  Q_PROPERTY (bool close_button_visible READ is_close_button_visible WRITE set_close_button_visible)
    //  Q_PROPERTY (Message_type message_type READ message_type WRITE set_message_type)
    //  Q_PROPERTY (QIcon icon READ icon WRITE set_icon)

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
    public KMessageWidget (Gtk.Widget parent = null);


    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent and
    contents @p text.
    ***********************************************************/
    public KMessageWidget (string text, Gtk.Widget parent = null);


    /***********************************************************
    Destructor.
    ***********************************************************/
    ~KMessageWidget () override;


    /***********************************************************
    Get the text of this message widget.
    @see on_set_text ()
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
    public void add_action (QAction action);


    /***********************************************************
    Remove @p action from the message widget.

    @param action the action to remove
    @see KMessageWidget.Message_type, add_action (), set_message_type ()
    ***********************************************************/
    public void remove_action (QAction action);


    /***********************************************************
    Returns the preferred size of the message widget.
    ***********************************************************/
    public QSize size_hint () override;


    /***********************************************************
    Returns the minimum size of the message widget.
    ***********************************************************/
    public QSize minimum_size_hint () override;


    /***********************************************************
    Returns the required height for @p width.
    @param width the width in pixels
    ***********************************************************/
    public int height_for_width (int width) override;


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


    /***********************************************************
    Set the text of the message widget to @p text.
    If the message widget is already visible, the text changes on the fly.

    @param text the text to display, rich text is allowed
    @see text ()
    ***********************************************************/
    public void on_set_text (string text);


    /***********************************************************
    Set word wrap to @p word_wrap. If word wrap is enabled, the text ()
    of the message widget is wrapped to fit the available width.
    If word wrap is disabled, the message widget's minimum size is
    such that the entire text fits.

    @param word_wrap disable/enable word wrap
    @see word_wrap ()
    ***********************************************************/
    public on_ void set_word_wrap (bool word_wrap);


    /***********************************************************
    Set the visibility of the close button. If @p visible is @e true,
    a close button is shown that calls animated_hide () if clicked.

    @see close_button_visible (), animated_hide ()
    ***********************************************************/
    public on_ void set_close_button_visible (bool visible);


    /***********************************************************
    Set the message type to @p type.
    By default, the message type is set to KMessageWidget.Information.
    Appropriate colors are chosen to mimic the appearance of Kirigami's
    Inline_message.

    @see message_type (), KMessageWidget.Message_type
    ***********************************************************/
    public on_ void set_message_type (KMessageWidget.Message_type type);


    /***********************************************************
    Show the widget using an animation.
    ***********************************************************/
    public on_ void animated_show ();


    /***********************************************************
    Hide the widget using an animation.
    ***********************************************************/
    public on_ void animated_hide ();


    /***********************************************************
    Define an icon to be shown on the left of the text
    @since 4.11
    ***********************************************************/
    public on_ void set_icon (QIcon icon);

signals:
    /***********************************************************
    This signal is emitted when the user clicks a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.link_activated ()
    @since 4.10
    ***********************************************************/
    void link_activated (string contents);


    /***********************************************************
    This signal is emitted when the user hovers over a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.link_hovered ()
    @since 4.11
    ***********************************************************/
    void link_hovered (string contents);


    /***********************************************************
    This signal is emitted when the hide animation is on_finished, started by
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
    This signal is emitted when the show animation is on_finished, started by
    calling animated_show (). If animations are disabled, this signal is
    emitted immediately after the message widget got shown.

    @note This signal is @e not emitted if the widget was shown by
          calling show (), so th
          with animated_s

    @see animated_show ()
    @since 5.0
    ***********************************************************/
    void show_animation_finished ();

    protected void paint_event (QPaint_event event) override;

    protected bool event (QEvent event) override;

    protected void resize_event (QResizeEvent event) override;


    /***********************************************************
    ***********************************************************/
    private KMessageWidgetPrivate const d;

    /***********************************************************
    ***********************************************************/
    private 
    private Q_PRIVATE_SLOT (d, void on_time_line_changed (qreal))
    private Q_PRIVATE_SLOT (d, void on_time_line_finished ())
}


    //---------------------------------------------------------------------
    // KMessageWidget
    //---------------------------------------------------------------------
    KMessageWidget.KMessageWidget (Gtk.Widget parent)
        : QFrame (parent)
        , d (new KMessageWidgetPrivate) {
        d.on_init (this);
    }

    KMessageWidget.KMessageWidget (string text, Gtk.Widget parent)
        : QFrame (parent)
        , d (new KMessageWidgetPrivate) {
        d.on_init (this);
        on_set_text (text);
    }

    KMessageWidget.~KMessageWidget () {
        delete d;
    }

    string KMessageWidget.text () {
        return d.text_label.text ();
    }

    void KMessageWidget.on_set_text (string text) {
        d.text_label.on_set_text (text);
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

    bool KMessageWidget.event (QEvent event) {
        if (event.type () == QEvent.Polish && !d.content.layout ()) {
            d.create_layout ();
        } else if (event.type () == QEvent.PaletteChange) {
            d.apply_style_sheet ();
        } else if (event.type () == QEvent.Show && !d.ignore_show_event_doing_animated_show) {
            if ( (height () != d.content.height ()) || (d.content.position ().y () != 0)) {
                d.content.move (0, 0);
                set_fixed_height (d.content.height ());
            }
        }
        return QFrame.event (event);
    }

    void KMessageWidget.resize_event (QResizeEvent event) {
        QFrame.resize_event (event);

        if (d.time_line.state () == QTime_line.Not_running) {
            d.content.resize (width (), d.best_content_height ());
        }
    }

    int KMessageWidget.height_for_width (int width) {
        ensure_polished ();
        return d.content.height_for_width (width);
    }

    void KMessageWidget.paint_event (QPaint_event event) {
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

    void KMessageWidget.add_action (QAction action) {
        QFrame.add_action (action);
        d.update_layout ();
    }

    void KMessageWidget.remove_action (QAction action) {
        QFrame.remove_action (action);
        d.update_layout ();
    }

    void KMessageWidget.animated_show () {
        // Test before style_hint, as there might have been a style change while animation was running
        if (is_hide_animation_running ()) {
            d.time_line.stop ();
            /* emit */ hide_animation_finished ();
        }

        if (!style ().style_hint (QStyle.SH_Widget_Animate, null, this)
         || (parent_widget () && !parent_widget ().is_visible ())) {
            show ();
            /* emit */ show_animation_finished ();
            return;
        }

        if (is_visible () && (d.time_line.state () == QTime_line.Not_running) && (height () == d.best_content_height ()) && (d.content.position ().y () == 0)) {
            /* emit */ show_animation_finished ();
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
            d.time_line.on_start ();
        }
    }

    void KMessageWidget.animated_hide () {
        // test this before is_visible, as animated_show might have been called directly before,
        // so the first timeline event is not yet done and the widget is still hidden
        // And before style_hint, as there might have been a style change while animation was running
        if (is_show_animation_running ()) {
            d.time_line.stop ();
            /* emit */ show_animation_finished ();
        }

        if (!style ().style_hint (QStyle.SH_Widget_Animate, null, this)) {
            hide ();
            /* emit */ hide_animation_finished ();
            return;
        }

        if (!is_visible ()) {
            // explicitly hide it, so it stays hidden in case it is only not visible due to the parents
            hide ();
            /* emit */ hide_animation_finished ();
            return;
        }

        d.content.move (0, -d.content.height ());
        d.update_snap_shot ();

        d.time_line.set_direction (QTime_line.Backward);
        if (d.time_line.state () == QTime_line.Not_running) {
            d.time_line.on_start ();
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

    void KMessageWidget.set_icon (QIcon icon) {
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

    