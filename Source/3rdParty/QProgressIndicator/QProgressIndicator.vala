/***********************************************************
The MIT License (MIT)

Copyright (c) 2011 Morgan Leborgne

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
***********************************************************/

// #include <Gtk.Widget>
// #include <QColor>

/***********************************************************
    \class QProgressIndicator
    \brief The QProgressIndicator class lets an application display a progress indicator to show that a lengthy task is under way.

    Progress indicators are indeterminate and do nothing more than spin to show that the application is busy.
    \sa QProgressBar
***********************************************************/
class QProgressIndicator : Gtk.Widget {
    Q_PROPERTY (int delay READ animationDelay WRITE setAnimationDelay)
    Q_PROPERTY (bool displayedWhenStopped READ isDisplayedWhenStopped WRITE setDisplayedWhenStopped)
    Q_PROPERTY (QColor color READ color WRITE setColor)

    public QProgressIndicator (Gtk.Widget* parent = nullptr);

    /*********************************************************** Returns the delay between animation steps.
        \return The number of milliseconds between animation steps. By default, the animation delay is set to 40 milliseconds.
        \sa setAnimationDelay
    ***********************************************************/
    public int animationDelay () {
        return m_delay;
    }

    /*********************************************************** Returns a Boolean value indicating whether the component is currently animated.
        \return Animation state.
        \sa startAnimation stopAnimation
    ***********************************************************/
    public bool isAnimated ();

    /*********************************************************** Returns a Boolean value indicating whether the receiver shows itself even when it is not animating.
        \return Return true if the progress indicator shows itself even when it is not animating. By default, it returns false.
        \sa setDisplayedWhenStopped
    ***********************************************************/
    public bool isDisplayedWhenStopped ();

    /*********************************************************** Returns the color of the component.
        \sa setColor
      */
      public const QColor & color () {
        return m_color;
    }

    public QSize sizeHint () const override;
    public int heightForWidth (int w) const override;
public slots:
    /*********************************************************** Starts the spin animation.
        \sa stopAnimation isAnimated
    ***********************************************************/
    void startAnimation ();

    /*********************************************************** Stops the spin animation.
        \sa startAnimation isAnimated
    ***********************************************************/
    void stopAnimation ();

    /*********************************************************** Sets the delay between animation steps.
        Setting the \a delay to a value larger than 40 slows the animation, while setting the \a delay to a smaller value speeds it up.
        \param delay The delay, in milliseconds.
        \sa animationDelay
    ***********************************************************/
    void setAnimationDelay (int delay);

    /*********************************************************** Sets whether the component hides itself when it is not animating.
       \param state The animation state. Set false to hide the progress indicator when it is not animating; otherwise true.
       \sa isDisplayedWhenStopped
    ***********************************************************/
    void setDisplayedWhenStopped (bool state);

    /*********************************************************** Sets the color of the components to the given color.
        \sa color
    ***********************************************************/
    void setColor (QColor & color);
protected:
    void timerEvent (QTimerEvent * event) override;
    void paintEvent (QPaintEvent * event) override;
private:
    int m_angle = 0;
    int m_timerId = -1;
    int m_delay = 40;
    bool m_displayedWhenStopped = false;
    QColor m_color = Qt.black;
};










/***********************************************************
The MIT License (MIT)

Copyright (c) 2011 Morgan Leborgne

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
in the Software without restriction, including without limitation the
to use, copy, modify, merge, publish, distribute, sublicens
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following condi

The above copyright notice and this permission notice shall be included
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
***********************************************************/

// #include <QPainter>

QProgressIndicator.QProgressIndicator (Gtk.Widget* parent)
    : Gtk.Widget (parent) {
    setSizePolicy (QSizePolicy.Fixed, QSizePolicy.Fixed);
    setFocusPolicy (Qt.NoFocus);
}

bool QProgressIndicator.isAnimated () {
    return (m_timerId != -1);
}

void QProgressIndicator.setDisplayedWhenStopped (bool state) {
    m_displayedWhenStopped = state;

    update ();
}

bool QProgressIndicator.isDisplayedWhenStopped () {
    return m_displayedWhenStopped;
}

void QProgressIndicator.startAnimation () {
    m_angle = 0;

    if (m_timerId == -1)
        m_timerId = startTimer (m_delay);
}

void QProgressIndicator.stopAnimation () {
    if (m_timerId != -1)
        killTimer (m_timerId);

    m_timerId = -1;

    update ();
}

void QProgressIndicator.setAnimationDelay (int delay) {
    if (m_timerId != -1)
        killTimer (m_timerId);

    m_delay = delay;

    if (m_timerId != -1)
        m_timerId = startTimer (m_delay);
}

void QProgressIndicator.setColor (QColor & color) {
    m_color = color;

    update ();
}

QSize QProgressIndicator.sizeHint () {
    return {20, 20};
}

int QProgressIndicator.heightForWidth (int w) {
    return w;
}

void QProgressIndicator.timerEvent (QTimerEvent * /*event*/) {
    m_angle = (m_angle+30)%360;

    update ();
}

void QProgressIndicator.paintEvent (QPaintEvent * /*event*/) {
    if (!m_displayedWhenStopped && !isAnimated ())
        return;

    int width = qMin (this.width (), this.height ());

    QPainter p (this);
    p.setRenderHint (QPainter.Antialiasing);

    int outerRadius = qRound ( (width - 1) * 0.5);
    int innerRadius = qRound ( (width - 1) * 0.5 * 0.38);

    int capsuleHeight = outerRadius - innerRadius;
    int capsuleWidth  = qRound ( (width > 32 ) ? capsuleHeight * 0.23 : capsuleHeight * 0.35);
    int capsuleRadius = capsuleWidth/2;

    for (int i=0; i<12; i++) {
        QColor color = m_color;
        color.setAlphaF (1.0f - (static_cast<float> (i) / 12.0f));
        p.setPen (Qt.NoPen);
        p.setBrush (color);
        p.save ();
        p.translate (rect ().center ());
        p.rotate (m_angle - i * 30);
        p.drawRoundedRect (qRound (-capsuleWidth * 0.5), - (innerRadius + capsuleHeight), capsuleWidth, capsuleHeight, capsuleRadius, capsuleRadius);
        p.restore ();
    }
}
