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
    Available message types.
    The background colors are chosen depending on the message type.
    ***********************************************************/
    enum MessageType {
        Positive,
        Information,
        Warning,
        Error
    };
    Q_ENUM (MessageType)

    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent.
    ***********************************************************/
    KMessageWidget (Gtk.Widget *parent = nullptr);

    /***********************************************************
    Constructs a KMessageWidget with the specified @p parent and
    contents @p text.
    ***********************************************************/
    KMessageWidget (string &text, Gtk.Widget *parent = nullptr);

    /***********************************************************
    Destructor.
    ***********************************************************/
    ~KMessageWidget () override;

    /***********************************************************
    Get the text of this message widget.
    @see setText ()
    ***********************************************************/
    string text ();

    /***********************************************************
    Check whether word wrap is enabled.
    
    If word wrap is enabled, the message widget wraps the displayed tex
    as required to the available wi
    avoid breaking widget layouts.

     * @see setWordWrap ()
    ***********************************************************/
    bool wordWrap ();

    /***********************************************************
    Check whether the close button is visible.
    
     * @see setCloseButtonVisible ()
    ***********************************************************/
    bool isCloseButtonVisible ();

    /***********************************************************
    Get the type of this message.
    By default, the type is set to KMessageWidget.Information.
    
     * @see KMessageWidget.MessageType, setMessageType ()
    ***********************************************************/
    MessageType messageType ();

    /***********************************************************
    Add @p action to the message widget.
    For each action a button is added to the message widget in the
    order the actions were added.
    
    @param action the action to add
     * @see removeAction (), Gtk.Widget.actions ()
    ***********************************************************/
    void addAction (QAction *action);

    /***********************************************************
    Remove @p action from the message widget.
    
    @param action the action to remove
     * @see KMessageWidget.MessageType, addAction (), setMessageType ()
    ***********************************************************/
    void removeAction (QAction *action);

    /***********************************************************
    Returns the preferred size of the message widget.
    ***********************************************************/
    QSize sizeHint () const override;

    /***********************************************************
    Returns the minimum size of the message widget.
    ***********************************************************/
    QSize minimumSizeHint () const override;

    /***********************************************************
    Returns the required height for @p width.
    @param width the width in pixels
    ***********************************************************/
    int heightForWidth (int width) const override;

    /***********************************************************
    The icon shown on the left of the text. By default, no icon is shown.
    @since 4.11
    ***********************************************************/
    QIcon icon ();

    /***********************************************************
    Check whether the hide animation started by calling animatedHide ()
    is still running. If animations are disabled, this function always
    returns @e false.
    
    @see animatedHide (), hideAnimationFinished ()
     * @since 5.0
    ***********************************************************/
    bool isHideAnimationRunning ();

    /***********************************************************
    Check whether the show animation started by calling animatedShow ()
    is still running. If animations are disabled, this function always
    returns @e false.
    
    @see animatedShow (), showAnimationFinished ()
     * @since 5.0
    ***********************************************************/
    bool isShowAnimationRunning ();

public slots:
    /***********************************************************
    Set the text of the message widget to @p text.
    If the message widget is already visible, the text changes on the fly.
    
    @param text the text to display, rich text is allowed
     * @see text ()
    ***********************************************************/
    void setText (string &text);

    /***********************************************************
    Set word wrap to @p wordWrap. If word wrap is enabled, the text ()
    of the message widget is wrapped to fit the available width.
    If word wrap is disabled, the message widget's minimum size is
    such that the entire text fits.
    
    @param wordWrap disable/enable word wrap
     * @see wordWrap ()
    ***********************************************************/
    void setWordWrap (bool wordWrap);

    /***********************************************************
    Set the visibility of the close button. If @p visible is @e true,
    a close button is shown that calls animatedHide () if clicked.
    
     * @see closeButtonVisible (), animatedHide ()
    ***********************************************************/
    void setCloseButtonVisible (bool visible);

    /***********************************************************
    Set the message type to @p type.
    By default, the message type is set to KMessageWidget.Information.
    Appropriate colors are chosen to mimic the appearance of Kirigami's
    InlineMessage.
    
     * @see messageType (), KMessageWidget.MessageType
    ***********************************************************/
    void setMessageType (KMessageWidget.MessageType type);

    /***********************************************************
    Show the widget using an animation.
    ***********************************************************/
    void animatedShow ();

    /***********************************************************
    Hide the widget using an animation.
    ***********************************************************/
    void animatedHide ();

    /***********************************************************
    Define an icon to be shown on the left of the text
    @since 4.11
    ***********************************************************/
    void setIcon (QIcon &icon);

signals:
    /***********************************************************
    This signal is emitted when the user clicks a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.linkActivated ()
    @since 4.10
    ***********************************************************/
    void linkActivated (string &contents);

    /***********************************************************
    This signal is emitted when the user hovers over a link in the text label.
    The URL referred to by the href anchor is passed in contents.
    @param contents text of the href anchor
    @see QLabel.linkHovered ()
    @since 4.11
    ***********************************************************/
    void linkHovered (string &contents);

    /***********************************************************
    This signal is emitted when the hide animation is finished, started by
    calling animatedHide (). If animations are disabled, this signal is
    emitted immediately after the message widget got hidden.
    
    @note This signal is @e not emitted if the widget was hidden by
          calling hide (), so th
          with animatedH
    
     * @see animatedHide ()
     * @since 5.0
    ***********************************************************/
    void hideAnimationFinished ();

    /***********************************************************
    This signal is emitted when the show animation is finished, started by
    calling animatedShow (). If animations are disabled, this signal is
    emitted immediately after the message widget got shown.
    
    @note This signal is @e not emitted if the widget was shown by
          calling show (), so th
          with animatedS
    
     * @see animatedShow ()
     * @since 5.0
    ***********************************************************/
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










/***********************************************************
This file is part of the KDE libraries

Copyright (c) 2011 Aurélien Gâteau <agateau@kde.org>
Copyright (c) 2014 Dominik Haumann <dhaumann@kde.org>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QAction>
// #include <QApplication>
// #include <QEvent>
// #include <QGridLayout>
// #include <QHBoxLayout>
// #include <QLabel>
// #include <QPainter>
// #include <QShowEvent>
// #include <QTimeLine>
// #include <QToolButton>
// #include <QStyle>

//---------------------------------------------------------------------
// KMessageWidgetPrivate
//---------------------------------------------------------------------
class KMessageWidgetPrivate {
    public:
        void init (KMessageWidget *);
    
        KMessageWidget *q;
        QFrame *content = nullptr;
        QLabel *iconLabel = nullptr;
        QLabel *textLabel = nullptr;
        QToolButton *closeButton = nullptr;
        QTimeLine *timeLine = nullptr;
        QIcon icon;
        bool ignoreShowEventDoingAnimatedShow = false;
    
        KMessageWidget.MessageType messageType;
        bool wordWrap;
        QList<QToolButton> buttons;
        QPixmap contentSnapShot;
    
        void createLayout ();
        void applyStyleSheet ();
        void updateSnapShot ();
        void updateLayout ();
        void slotTimeLineChanged (qreal);
        void slotTimeLineFinished ();
    
        int bestContentHeight ();
    };
    
    void KMessageWidgetPrivate.init (KMessageWidget *q_ptr) {
        q = q_ptr;
    
        q.setSizePolicy (QSizePolicy.Minimum, QSizePolicy.Fixed);
    
        // Note : when changing the value 500, also update KMessageWidgetTest
        timeLine = new QTimeLine (500, q);
        GLib.Object.connect (timeLine, SIGNAL (valueChanged (qreal)), q, SLOT (slotTimeLineChanged (qreal)));
        GLib.Object.connect (timeLine, SIGNAL (finished ()), q, SLOT (slotTimeLineFinished ()));
    
        content = new QFrame (q);
        content.setObjectName (QStringLiteral ("contentWidget"));
        content.setSizePolicy (QSizePolicy.Expanding, QSizePolicy.Fixed);
    
        wordWrap = false;
    
        iconLabel = new QLabel (content);
        iconLabel.setSizePolicy (QSizePolicy.Fixed, QSizePolicy.Fixed);
        iconLabel.hide ();
    
        textLabel = new QLabel (content);
        textLabel.setSizePolicy (QSizePolicy.Expanding, QSizePolicy.Fixed);
        textLabel.setTextInteractionFlags (Qt.TextBrowserInteraction);
        GLib.Object.connect (textLabel, &QLabel.linkActivated, q, &KMessageWidget.linkActivated);
        GLib.Object.connect (textLabel, &QLabel.linkHovered, q, &KMessageWidget.linkHovered);
    
        auto *closeAction = new QAction (q);
        closeAction.setText (KMessageWidget.tr ("&Close"));
        closeAction.setToolTip (KMessageWidget.tr ("Close message"));
        closeAction.setIcon (QIcon (":/client/theme/close.svg")); // ivan : NC customization
    
        GLib.Object.connect (closeAction, &QAction.triggered, q, &KMessageWidget.animatedHide);
    
        closeButton = new QToolButton (content);
        closeButton.setAutoRaise (true);
        closeButton.setDefaultAction (closeAction);
    
        q.setMessageType (KMessageWidget.Information);
    }
    
    void KMessageWidgetPrivate.createLayout () {
        delete content.layout ();
    
        content.resize (q.size ());
    
        qDeleteAll (buttons);
        buttons.clear ();
    
        Q_FOREACH (QAction *action, q.actions ()) {
            auto *button = new QToolButton (content);
            button.setDefaultAction (action);
            button.setToolButtonStyle (Qt.ToolButtonTextBesideIcon);
            buttons.append (button);
        }
    
        // AutoRaise reduces visual clutter, but we don't want to turn it on if
        // there are other buttons, otherwise the close button will look different
        // from the others.
        closeButton.setAutoRaise (buttons.isEmpty ());
    
        if (wordWrap) {
            auto *layout = new QGridLayout (content);
            // Set alignment to make sure icon does not move down if text wraps
            layout.addWidget (iconLabel, 0, 0, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            layout.addWidget (textLabel, 0, 1);
    
            if (buttons.isEmpty ()) {
                // Use top-vertical alignment like the icon does.
                layout.addWidget (closeButton, 0, 2, 1, 1, Qt.AlignHCenter | Qt.AlignTop);
            } else {
                // Use an additional layout in row 1 for the buttons.
                auto *buttonLayout = new QHBoxLayout;
                buttonLayout.addStretch ();
                Q_FOREACH (QToolButton *button, buttons) {
                    // For some reason, calling show () is necessary if wordwrap is true,
                    // otherwise the buttons do not show up. It is not needed if
                    // wordwrap is false.
                    button.show ();
                    buttonLayout.addWidget (button);
                }
                buttonLayout.addWidget (closeButton);
                layout.addItem (buttonLayout, 1, 0, 1, 2);
            }
        } else {
            auto *layout = new QHBoxLayout (content);
            layout.addWidget (iconLabel);
            layout.addWidget (textLabel);
    
            for (QToolButton *button : qAsConst (buttons)) {
                layout.addWidget (button);
            }
    
            layout.addWidget (closeButton);
        };
    
        if (q.isVisible ()) {
            q.setFixedHeight (content.sizeHint ().height ());
        }
        q.updateGeometry ();
    }
    
    void KMessageWidgetPrivate.applyStyleSheet () {
        QColor bgBaseColor;
    
        // We have to hardcode colors here because KWidgetsAddons is a tier 1 framework
        // and therefore can't depend on any other KDE Frameworks
        // The following RGB color values come from the "default" scheme in kcolorscheme.cpp
        switch (messageType) {
        case KMessageWidget.Positive:
            bgBaseColor.setRgb (39, 174,  96); // Window : ForegroundPositive
            break;
        case KMessageWidget.Information:
            bgBaseColor.setRgb (61, 174, 233); // Window : ForegroundActive
            break;
        case KMessageWidget.Warning:
            bgBaseColor.setRgb (246, 116, 0); // Window : ForegroundNeutral
            break;
        case KMessageWidget.Error:
            bgBaseColor.setRgb (218, 68, 83); // Window : ForegroundNegative
            break;
        }
        const qreal bgBaseColorAlpha = 0.2;
        bgBaseColor.setAlphaF (bgBaseColorAlpha);
    
        const QPalette palette = QGuiApplication.palette ();
        const QColor windowColor = palette.window ().color ();
        const QColor textColor = palette.text ().color ();
        const QColor border = bgBaseColor;
    
        // Generate a final background color from overlaying bgBaseColor over windowColor
        const int newRed = qRound (bgBaseColor.red () * bgBaseColorAlpha) + qRound (windowColor.red () * (1 - bgBaseColorAlpha));
        const int newGreen = qRound (bgBaseColor.green () * bgBaseColorAlpha) + qRound (windowColor.green () * (1 - bgBaseColorAlpha));
        const int newBlue = qRound (bgBaseColor.blue () * bgBaseColorAlpha) + qRound (windowColor.blue () * (1 - bgBaseColorAlpha));
    
        const QColor bgFinalColor = QColor (newRed, newGreen, newBlue);
    
        content.setStyleSheet (
            string.fromLatin1 (".QFrame {"
                                  "background-color : %1;"
                                  "border-radius : 4px;"
                                  "border : 2px solid %2;"
                                  "margin : %3px;"
                                  "}"
                                  ".QLabel { color : %4; }"
                                 )
            .arg (bgFinalColor.name ())
            .arg (border.name ())
            // DefaultFrameWidth returns the size of the external margin + border width. We know our border is 1px, so we subtract this from the frame normal QStyle FrameWidth to get our margin
            .arg (q.style ().pixelMetric (QStyle.PM_DefaultFrameWidth, nullptr, q) - 1)
            .arg (textColor.name ())
        );
    }
    
    void KMessageWidgetPrivate.updateLayout () {
        if (content.layout ()) {
            createLayout ();
        }
    }
    
    void KMessageWidgetPrivate.updateSnapShot () {
        // Attention : updateSnapShot calls Gtk.Widget.render (), which causes the whole
        // window layouts to be activated. Calling this method from resizeEvent ()
        // can lead to infinite recursion, see:
        // https://bugs.kde.org/show_bug.cgi?id=311336
        contentSnapShot = QPixmap (content.size () * q.devicePixelRatio ());
        contentSnapShot.setDevicePixelRatio (q.devicePixelRatio ());
        contentSnapShot.fill (Qt.transparent);
        content.render (&contentSnapShot, QPoint (), QRegion (), Gtk.Widget.DrawChildren);
    }
    
    void KMessageWidgetPrivate.slotTimeLineChanged (qreal value) {
        q.setFixedHeight (qMin (qRound (value * 2.0), 1) * content.height ());
        q.update ();
    }
    
    void KMessageWidgetPrivate.slotTimeLineFinished () {
        if (timeLine.direction () == QTimeLine.Forward) {
            // Show
            // We set the whole geometry here, because it may be wrong if a
            // KMessageWidget is shown right when the toplevel window is created.
            content.setGeometry (0, 0, q.width (), bestContentHeight ());
    
            // notify about finished animation
            emit q.showAnimationFinished ();
        } else {
            // hide and notify about finished animation
            q.hide ();
            emit q.hideAnimationFinished ();
        }
    }
    
    int KMessageWidgetPrivate.bestContentHeight () {
        int height = content.heightForWidth (q.width ());
        if (height == -1) {
            height = content.sizeHint ().height ();
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
        setText (text);
    }
    
    KMessageWidget.~KMessageWidget () {
        delete d;
    }
    
    string KMessageWidget.text () {
        return d.textLabel.text ();
    }
    
    void KMessageWidget.setText (string &text) {
        d.textLabel.setText (text);
        updateGeometry ();
    }
    
    KMessageWidget.MessageType KMessageWidget.messageType () {
        return d.messageType;
    }
    
    void KMessageWidget.setMessageType (KMessageWidget.MessageType type) {
        d.messageType = type;
        d.applyStyleSheet ();
    }
    
    QSize KMessageWidget.sizeHint () {
        ensurePolished ();
        return d.content.sizeHint ();
    }
    
    QSize KMessageWidget.minimumSizeHint () {
        ensurePolished ();
        return d.content.minimumSizeHint ();
    }
    
    bool KMessageWidget.event (QEvent *event) {
        if (event.type () == QEvent.Polish && !d.content.layout ()) {
            d.createLayout ();
        } else if (event.type () == QEvent.PaletteChange) {
            d.applyStyleSheet ();
        } else if (event.type () == QEvent.Show && !d.ignoreShowEventDoingAnimatedShow) {
            if ( (height () != d.content.height ()) || (d.content.pos ().y () != 0)) {
                d.content.move (0, 0);
                setFixedHeight (d.content.height ());
            }
        }
        return QFrame.event (event);
    }
    
    void KMessageWidget.resizeEvent (QResizeEvent *event) {
        QFrame.resizeEvent (event);
    
        if (d.timeLine.state () == QTimeLine.NotRunning) {
            d.content.resize (width (), d.bestContentHeight ());
        }
    }
    
    int KMessageWidget.heightForWidth (int width) {
        ensurePolished ();
        return d.content.heightForWidth (width);
    }
    
    void KMessageWidget.paintEvent (QPaintEvent *event) {
        QFrame.paintEvent (event);
        if (d.timeLine.state () == QTimeLine.Running) {
            QPainter painter (this);
            painter.setOpacity (d.timeLine.currentValue () * d.timeLine.currentValue ());
            painter.drawPixmap (0, 0, d.contentSnapShot);
        }
    }
    
    bool KMessageWidget.wordWrap () {
        return d.wordWrap;
    }
    
    void KMessageWidget.setWordWrap (bool wordWrap) {
        d.wordWrap = wordWrap;
        d.textLabel.setWordWrap (wordWrap);
        QSizePolicy policy = sizePolicy ();
        policy.setHeightForWidth (wordWrap);
        setSizePolicy (policy);
        d.updateLayout ();
        // Without this, when user does wordWrap . !wordWrap . wordWrap, a minimum
        // height is set, causing the widget to be too high.
        // Mostly visible in test programs.
        if (wordWrap) {
            setMinimumHeight (0);
        }
    }
    
    bool KMessageWidget.isCloseButtonVisible () {
        return d.closeButton.isVisible ();
    }
    
    void KMessageWidget.setCloseButtonVisible (bool show) {
        d.closeButton.setVisible (show);
        updateGeometry ();
    }
    
    void KMessageWidget.addAction (QAction *action) {
        QFrame.addAction (action);
        d.updateLayout ();
    }
    
    void KMessageWidget.removeAction (QAction *action) {
        QFrame.removeAction (action);
        d.updateLayout ();
    }
    
    void KMessageWidget.animatedShow () {
        // Test before styleHint, as there might have been a style change while animation was running
        if (isHideAnimationRunning ()) {
            d.timeLine.stop ();
            emit hideAnimationFinished ();
        }
    
        if (!style ().styleHint (QStyle.SH_Widget_Animate, nullptr, this)
         || (parentWidget () && !parentWidget ().isVisible ())) {
            show ();
            emit showAnimationFinished ();
            return;
        }
    
        if (isVisible () && (d.timeLine.state () == QTimeLine.NotRunning) && (height () == d.bestContentHeight ()) && (d.content.pos ().y () == 0)) {
            emit showAnimationFinished ();
            return;
        }
    
        d.ignoreShowEventDoingAnimatedShow = true;
        show ();
        d.ignoreShowEventDoingAnimatedShow = false;
        setFixedHeight (0);
        int wantedHeight = d.bestContentHeight ();
        d.content.setGeometry (0, -wantedHeight, width (), wantedHeight);
    
        d.updateSnapShot ();
    
        d.timeLine.setDirection (QTimeLine.Forward);
        if (d.timeLine.state () == QTimeLine.NotRunning) {
            d.timeLine.start ();
        }
    }
    
    void KMessageWidget.animatedHide () {
        // test this before isVisible, as animatedShow might have been called directly before,
        // so the first timeline event is not yet done and the widget is still hidden
        // And before styleHint, as there might have been a style change while animation was running
        if (isShowAnimationRunning ()) {
            d.timeLine.stop ();
            emit showAnimationFinished ();
        }
    
        if (!style ().styleHint (QStyle.SH_Widget_Animate, nullptr, this)) {
            hide ();
            emit hideAnimationFinished ();
            return;
        }
    
        if (!isVisible ()) {
            // explicitly hide it, so it stays hidden in case it is only not visible due to the parents
            hide ();
            emit hideAnimationFinished ();
            return;
        }
    
        d.content.move (0, -d.content.height ());
        d.updateSnapShot ();
    
        d.timeLine.setDirection (QTimeLine.Backward);
        if (d.timeLine.state () == QTimeLine.NotRunning) {
            d.timeLine.start ();
        }
    }
    
    bool KMessageWidget.isHideAnimationRunning () {
        return (d.timeLine.direction () == QTimeLine.Backward)
            && (d.timeLine.state () == QTimeLine.Running);
    }
    
    bool KMessageWidget.isShowAnimationRunning () {
        return (d.timeLine.direction () == QTimeLine.Forward)
            && (d.timeLine.state () == QTimeLine.Running);
    }
    
    QIcon KMessageWidget.icon () {
        return d.icon;
    }
    
    void KMessageWidget.setIcon (QIcon &icon) {
        d.icon = icon;
        if (d.icon.isNull ()) {
            d.iconLabel.hide ();
        } else {
            const int size = style ().pixelMetric (QStyle.PM_ToolBarIconSize);
            d.iconLabel.setPixmap (d.icon.pixmap (size));
            d.iconLabel.show ();
        }
    }
    
    #include "moc_kmessagewidget.cpp"
    
    