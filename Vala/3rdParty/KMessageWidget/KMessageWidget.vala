/***********************************************************
@class KMessageWidget kmessagewidget.h KMessageWidget

@short A widget to provide feedback or propose opportunistic inte

KMessageWidget can be used to provide inline positive or negative
feedback, or to implement opportunistic interactions.

As a feedback widget, KMessageWidget provides a less intrusive alternative
to "OK Only" message boxes. If you want to avoid a modal KMe
consider using KMessageWidget instead.

Examples of KMessageWidget look as follows, all of them having an icon
with on_signal_set_icon (), and the first three show a close button:

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

This file is part of the KDE libraries

@author  Aurélien Gâteau <agateau@kde.org>
@since 4.7

@author 2011 Aurélien Gâteau <agateau@kde.org>
@author 2014 Dominik Haumann <dhaumann@kde.org>

@copyright LGPLv2.1 or later
***********************************************************/
public class KMessageWidget : Gdk.Frame {

    //  Q_PROPERTY (string text READ text WRITE on_set_text)
    //  Q_PROPERTY (bool word_wrap READ word_wrap WRITE on_signal_set_word_wrap)
    //  Q_PROPERTY (bool close_button_visible READ is_close_button_visible WRITE on_signal_set_close_button_visible)
    //  Q_PROPERTY (MessageType message_type READ message_type WRITE on_signal_set_message_type)
    //  Q_PROPERTY (Gtk.Icon icon READ icon WRITE on_signal_set_icon)

    //  private Q_PRIVATE_SLOT (d, void on_time_line_changed (double))
    //  private Q_PRIVATE_SLOT (d, void on_time_line_finished ())

    /***********************************************************
    Available message types.
    The background colors are chosen depending on the message type.
    ***********************************************************/
    public enum MessageType {
        Positive,
        Information,
        Warning,
        Error
    }


    /***********************************************************
    ***********************************************************/
    public KMessageWidgetPrivate d { public get; construct; }

    /***********************************************************
    This signal is emitted when the user clicks a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see Gtk.Label.link_activated ()
    @since 4.10
    ***********************************************************/
    internal signal void link_activated (string contents);

    /***********************************************************
    This signal is emitted when the user hovers over a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see Gtk.Label.link_hovered ()
    @since 4.11
    ***********************************************************/
    internal signal void link_hovered (string contents);

    /***********************************************************
    This signal is emitted when the hide animation is on_finished, started by
    calling on_signal_animated_hide (). If animations are disabled, this signal is
    emitted immediately after the message widget got hidden.

    @note This signal is @e not emitted if the widget was hidden by
          calling hide (), so th
          with animated_h

    @see on_signal_animated_hide ()
    @since 5.0
    ***********************************************************/
    internal signal void hide_animation_finished ();

    /***********************************************************
    This signal is emitted when the show animation is on_finished, started by
    calling on_signal_animated_show (). If animations are disabled, this signal is
    emitted immediately after the message widget got shown.

    @note This signal is @e not emitted if the widget was shown by
          calling show (), so th
          with animated_s

    @see on_signal_animated_show ()
    @since 5.0
    ***********************************************************/
    internal signal void show_animation_finished ();


    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent.
    ***********************************************************/
    public KMessageWidget (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        d = new KMessageWidgetPrivate ();
        d.on_init (this);
    }


    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent and
    contents @p text.
    ***********************************************************/
    public KMessageWidget.for_string (string text, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        d = new KMessageWidgetPrivate ();
        d.on_init (this);
        on_set_text (text);
    }


    /***********************************************************
    Destructor.
    ***********************************************************/
    override ~KMessageWidget () {
        delete d;
    }


    /***********************************************************
    Get the text of this message widget.
    @see on_set_text ()
    ***********************************************************/
    public string text {
        public get {
            return d.text_label.text ();
        }
    }


    /***********************************************************
    Check whether word wrap is enabled.

    If word wrap is enabled, the message widget wraps the displayed tex
    as required to the available wi
    avoid breaking widget layouts.

    @see on_signal_set_word_wrap ()
    ***********************************************************/
    public bool word_wrap () {
        return d.word_wrap;
    }


    /***********************************************************
    Check whether the close button is visible.

    @see on_signal_set_close_button_visible ()
    ***********************************************************/
    public bool is_close_button_visible () {
        return d.close_button.is_visible ();
    }


    /***********************************************************
    Get the type of this message.
    By default, the type is set to KMessageWidget.Information.

    @see KMessageWidget.MessageType, on_signal_set_message_type ()
    ***********************************************************/
    public MessageType message_type () {
        return d.message_type;
    }


    /***********************************************************
    Add @p action to the message widget.
    For each action a button is added to the message widget in the
    order the actions were added.

    @param action the action to add
    @see remove_action (), Gtk.Widget.actions ()
    ***********************************************************/
    public void add_action (GLib.Action action) {
        Gdk.Frame.add_action (action);
        d.update_layout ();
    }


    /***********************************************************
    Remove @p action from the message widget.

    @param action the action to remove
    @see KMessageWidget.MessageType, add_action (), on_signal_set_message_type ()
    ***********************************************************/
    public void remove_action (GLib.Action action) {
        Gdk.Frame.remove_action (action);
        d.update_layout ();
    }


    /***********************************************************
    Returns the preferred size of the message widget.
    ***********************************************************/
    public override Gdk.Rectangle size_hint () {
        ensure_polished ();
        return d.content.size_hint ();
    }


    /***********************************************************
    Returns the minimum size of the message widget.
    ***********************************************************/
    public override Gdk.Rectangle minimum_size_hint () {
        ensure_polished ();
        return d.content.minimum_size_hint ();
    }


    /***********************************************************
    Returns the required height for @p width.
    @param width the width in pixels
    ***********************************************************/
    public override int height_for_width (int width) {
        ensure_polished ();
        return d.content.height_for_width (width);
    }


    /***********************************************************
    The icon shown on the left of the text. By default, no icon is shown.
    @since 4.11
    ***********************************************************/
    public Gtk.Icon icon () {
        return d.icon;
    }


    /***********************************************************
    Check whether the hide animation started by calling on_signal_animated_hide ()
    is still running. If animations are disabled, this function always
    returns @e false.

    @see on_signal_animated_hide (), hide_animation_finished ()
    @since 5.0
    ***********************************************************/
    public bool is_hide_animation_running () {
        return (d.time_line.direction () == GLib.TimeLine.Backward)
            && (d.time_line.state == GLib.TimeLine.Running);
    }


    /***********************************************************
    Check whether the show animation started by calling on_signal_animated_show ()
    is still running. If animations are disabled, this function always
    returns @e false.

    @see on_signal_animated_show (), show_animation_finished ()
    @since 5.0
    ***********************************************************/
    public bool is_show_animation_running () {
        return (d.time_line.direction () == GLib.TimeLine.Forward)
            && (d.time_line.state == GLib.TimeLine.Running);
    }


    /***********************************************************
    Set the text of the message widget to @p text.
    If the message widget is already visible, the text changes on the fly.

    @param text the text to display, rich text is allowed
    @see text ()
    ***********************************************************/
    public void on_set_text (string text) {
        d.text_label.on_set_text (text);
        update_geometry ();
    }


    /***********************************************************
    Set word wrap to @p word_wrap. If word wrap is enabled, the text ()
    of the message widget is wrapped to fit the available width.
    If word wrap is disabled, the message widget's minimum size is
    such that the entire text fits.

    @param word_wrap disable/enable word wrap
    @see word_wrap ()
    ***********************************************************/
    public void on_signal_set_word_wrap (bool word_wrap) {
        d.word_wrap = word_wrap;
        d.text_label.on_signal_set_word_wrap (word_wrap);
        GLib.SizePolicy policy = size_policy ();
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


    /***********************************************************
    Set the visibility of the close button. If @p visible is @e true,
    a close button is shown that calls on_signal_animated_hide () if clicked.

    @see close_button_visible (), on_signal_animated_hide ()
    ***********************************************************/
    public void on_signal_set_close_button_visible (bool visible) {
        d.close_button.set_visible (show);
        update_geometry ();
    }


    /***********************************************************
    Set the message type to @p type.
    By default, the message type is set to KMessageWidget.Information.
    Appropriate colors are chosen to mimic the appearance of Kirigami's
    InlineMessage.

    @see message_type (), KMessageWidget.MessageType
    ***********************************************************/
    public void on_signal_set_message_type (KMessageWidget.MessageType type) {
        d.message_type = type;
        d.apply_style_sheet ();
    }


    /***********************************************************
    Show the widget using an animation.
    ***********************************************************/
    public void on_signal_animated_show () {
        // Test before style_hint, as there might have been a style change while animation was running
        if (is_hide_animation_running ()) {
            d.time_line.stop ();
            /* emit */ hide_animation_finished ();
        }

        if (!this.style.style_hint (GLib.Style.SH_WidgetAnimate, null, this)
         || (parent_widget () && !parent_widget ().is_visible ())) {
            show ();
            /* emit */ show_animation_finished ();
            return;
        }

        if (is_visible () && (d.time_line.state == GLib.TimeLine.NotRunning) && (height () == d.best_content_height ()) && (d.content.position ().y () == 0)) {
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

        d.time_line.set_direction (GLib.TimeLine.Forward);
        if (d.time_line.state == GLib.TimeLine.NotRunning) {
            d.time_line.on_start ();
        }
    }


    /***********************************************************
    Hide the widget using an animation.
    ***********************************************************/
    public void on_signal_animated_hide () {
        // test this before is_visible, as on_signal_animated_show might have been called directly before,
        // so the first timeline event is not yet done and the widget is still hidden
        // And before style_hint, as there might have been a style change while animation was running
        if (is_show_animation_running ()) {
            d.time_line.stop ();
            /* emit */ show_animation_finished ();
        }

        if (!this.style.style_hint (GLib.Style.SH_WidgetAnimate, null, this)) {
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

        d.time_line.set_direction (GLib.TimeLine.Backward);
        if (d.time_line.state == GLib.TimeLine.NotRunning) {
            d.time_line.on_start ();
        }
    }


    /***********************************************************
    Define an icon to be shown on the left of the text
    @since 4.11
    ***********************************************************/
    public void on_signal_set_icon (Gtk.Icon icon) {
        d.icon = icon;
        if (d.icon == null) {
            d.icon_label.hide ();
        } else {
            int size = this.style.pixel_metric (GLib.Style.PM_ToolBarIconSize);
            d.icon_label.set_pixmap (d.icon.pixmap (size));
            d.icon_label.show ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected override void paint_event (GLib.PaintEvent event) {
        Gdk.Frame.paint_event (event);
        if (d.time_line.state == GLib.TimeLine.Running) {
            GLib.Painter painter = new GLib.Painter (this);
            painter.set_opacity (d.time_line.current_value () * d.time_line.current_value ());
            painter.draw_pixmap (0, 0, d.content_snap_shot);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected override bool event (Gdk.Event event) {
        if (event.type () == Gdk.Event.Polish && !d.content.layout ()) {
            d.create_layout ();
        } else if (event.type () == Gdk.Event.PaletteChange) {
            d.apply_style_sheet ();
        } else if (event.type () == Gdk.Event.Show && !d.ignore_show_event_doing_animated_show) {
            if ( (height () != d.content.height ()) || (d.content.position ().y () != 0)) {
                d.content.move (0, 0);
                set_fixed_height (d.content.height ());
            }
        }
        return Gdk.Frame.event (event);
    }


    /***********************************************************
    ***********************************************************/
    protected override void resize_event (GLib.ResizeEvent event) {
        Gdk.Frame.resize_event (event);

        if (d.time_line.state == GLib.TimeLine.NotRunning) {
            d.content.resize (width (), d.best_content_height ());
        }
    }

}
