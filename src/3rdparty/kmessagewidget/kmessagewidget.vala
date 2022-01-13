/* This file is part of the KDE libraries

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
with setIcon (), and the first three show a close button:

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

    Q_PROPERTY (string text READ text WRITE setText)
    Q_PROPERTY (bool wordWrap READ wordWrap WRITE setWordWrap)
    Q_PROPERTY (bool closeButtonVisible READ isCloseButtonVisible WRITE setCloseButtonVisible)
    Q_PROPERTY (MessageType messageType READ messageType WRITE setMessageType)
    Q_PROPERTY (QIcon icon READ icon WRITE setIcon)
public:

    /***********************************************************
     * Available message types.
     * The background colors are chosen depending on the message type.
     */
    enum MessageType {
        Positive,
        Information,
        Warning,
        Error
    };
    Q_ENUM (MessageType)

    /***********************************************************
     * Constructs a KMessageWidget with the specified @p parent.
     */
    KMessageWidget (Gtk.Widget *parent = nullptr);

    /***********************************************************
     * Constructs a KMessageWidget with the specified @p parent and
     * contents @p text.
     */
    KMessageWidget (string &text, Gtk.Widget *parent = nullptr);

    /***********************************************************
     * Destructor.
     */
    ~KMessageWidget () override;

    /***********************************************************
     * Get the text of this message widget.
     * @see setText ()
     */
    string text ();

    /***********************************************************
     * Check whether word wrap is enabled.
     *
     * If word wrap is enabled, the message widget wraps the displayed text
     * as required to the available width of the widget. This is useful to
     * avoid breaking widget layouts.
     *
     * @see setWordWrap ()
     */
    bool wordWrap ();

    /***********************************************************
     * Check whether the close button is visible.
     *
     * @see setCloseButtonVisible ()
     */
    bool isCloseButtonVisible ();

    /***********************************************************
     * Get the type of this message.
     * By default, the type is set to KMessageWidget.Information.
     *
     * @see KMessageWidget.MessageType, setMessageType ()
     */
    MessageType messageType ();

    /***********************************************************
     * Add @p action to the message widget.
     * For each action a button is added to the message widget in the
     * order the actions were added.
     *
     * @param action the action to add
     * @see removeAction (), Gtk.Widget.actions ()
     */
    void addAction (QAction *action);

    /***********************************************************
     * Remove @p action from the message widget.
     *
     * @param action the action to remove
     * @see KMessageWidget.MessageType, addAction (), setMessageType ()
     */
    void removeAction (QAction *action);

    /***********************************************************
     * Returns the preferred size of the message widget.
     */
    QSize sizeHint () const override;

    /***********************************************************
     * Returns the minimum size of the message widget.
     */
    QSize minimumSizeHint () const override;

    /***********************************************************
     * Returns the required height for @p width.
     * @param width the width in pixels
     */
    int heightForWidth (int width) const override;

    /***********************************************************
     * The icon shown on the left of the text. By default, no icon is shown.
     * @since 4.11
     */
    QIcon icon ();

    /***********************************************************
     * Check whether the hide animation started by calling animatedHide ()
     * is still running. If animations are disabled, this function always
     * returns @e false.
     *
     * @see animatedHide (), hideAnimationFinished ()
     * @since 5.0
     */
    bool isHideAnimationRunning ();

    /***********************************************************
     * Check whether the show animation started by calling animatedShow ()
     * is still running. If animations are disabled, this function always
     * returns @e false.
     *
     * @see animatedShow (), showAnimationFinished ()
     * @since 5.0
     */
    bool isShowAnimationRunning ();

public slots:
    /***********************************************************
     * Set the text of the message widget to @p text.
     * If the message widget is already visible, the text changes on the fly.
     *
     * @param text the text to display, rich text is allowed
     * @see text ()
     */
    void setText (string &text);

    /***********************************************************
     * Set word wrap to @p wordWrap. If word wrap is enabled, the text ()
     * of the message widget is wrapped to fit the available width.
     * If word wrap is disabled, the message widget's minimum size is
     * such that the entire text fits.
     *
     * @param wordWrap disable/enable word wrap
     * @see wordWrap ()
     */
    void setWordWrap (bool wordWrap);

    /***********************************************************
     * Set the visibility of the close button. If @p visible is @e true,
     * a close button is shown that calls animatedHide () if clicked.
     *
     * @see closeButtonVisible (), animatedHide ()
     */
    void setCloseButtonVisible (bool visible);

    /***********************************************************
     * Set the message type to @p type.
     * By default, the message type is set to KMessageWidget.Information.
     * Appropriate colors are chosen to mimic the appearance of Kirigami's
     * InlineMessage.
     *
     * @see messageType (), KMessageWidget.MessageType
     */
    void setMessageType (KMessageWidget.MessageType type);

    /***********************************************************
     * Show the widget using an animation.
     */
    void animatedShow ();

    /***********************************************************
     * Hide the widget using an animation.
     */
    void animatedHide ();

    /***********************************************************
     * Define an icon to be shown on the left of the text
     * @since 4.11
     */
    void setIcon (QIcon &icon);

signals:
    /***********************************************************
     * This signal is emitted when the user clicks a link in the text label.
     * The URL referred to by the href anchor is passed in contents.
     * @param contents text of the href anchor
     * @see QLabel.linkActivated ()
     * @since 4.10
     */
    void linkActivated (string &contents);

    /***********************************************************
     * This signal is emitted when the user hovers over a link in the text label.
     * The URL referred to by the href anchor is passed in contents.
     * @param contents text of the href anchor
     * @see QLabel.linkHovered ()
     * @since 4.11
     */
    void linkHovered (string &contents);

    /***********************************************************
     * This signal is emitted when the hide animation is finished, started by
     * calling animatedHide (). If animations are disabled, this signal is
     * emitted immediately after the message widget got hidden.
     *
     * @note This signal is @e not emitted if the widget was hidden by
     *       calling hide (), so this signal is only useful in conjunction
     *       with animatedHide ().
     *
     * @see animatedHide ()
     * @since 5.0
     */
    void hideAnimationFinished ();

    /***********************************************************
     * This signal is emitted when the show animation is finished, started by
     * calling animatedShow (). If animations are disabled, this signal is
     * emitted immediately after the message widget got shown.
     *
     * @note This signal is @e not emitted if the widget was shown by
     *       calling show (), so this signal is only useful in conjunction
     *       with animatedShow ().
     *
     * @see animatedShow ()
     * @since 5.0
     */
    void showAnimationFinished ();

protected:
    void paintEvent (QPaintEvent *event) override;

    bool event (QEvent *event) override;

    void resizeEvent (QResizeEvent *event) override;

private:
    KMessageWidgetPrivate *const d;
    friend class KMessageWidgetPrivate;

    Q_PRIVATE_SLOT (d, void slotTimeLineChanged (qreal))
    Q_PRIVATE_SLOT (d, void slotTimeLineFinished ())
};

#endif /* KMESSAGEWIDGET_H */
