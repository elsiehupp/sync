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

//  #include <Gtk.Widget>
//  #include <Gtk.Color>

/***********************************************************
    \class QProgressIndicator
    \brief The QProgressIndicator class lets an application display a progress indicator to show that a lengthy task is under way.

    Progress indicators are indeterminate and do nothing more than spin to show that the application is busy.
    \sa QProgressBar
***********************************************************/
public class QProgressIndicator : Gtk.Widget {
    //  Q_PROPERTY (int delay READ animation_delay WRITE on_set_animation_delay)
    //  Q_PROPERTY (bool displayed_when_stopped READ is_displayed_when_stopped WRITE on_set_displayed_when_stopped)
    //  Q_PROPERTY (Gtk.Color color READ color WRITE on_set_color)

    /***********************************************************
    ***********************************************************/
    public QProgressIndicator (Gtk.Widget* parent = null);


    /***********************************************************
    Returns the delay between animation steps.
    \return The number of milliseconds between animation steps. By default, the animation delay is set to 40 milliseconds.
    \sa on_set_animation_delay
    ***********************************************************/
    public int animation_delay () {
        return m_delay;
    }


    /***********************************************************
    Returns a Boolean value indicating whether the component is currently animated.
    \return Animation state.
    \sa on_start_animation on_stop_animation
    ***********************************************************/
    public bool is_animated ();


    /***********************************************************
    Returns a Boolean value indicating whether the receiver shows itself even when it is not animating.
    \return Return true if the progress indicator shows itself even when it is not animating. By default, it returns false.
    \sa on_set_displayed_when_stopped
    ***********************************************************/
    public bool is_displayed_when_stopped ();


    /***********************************************************
    Returns the color of the component.
    \sa on_set_color
    ***********************************************************/
      public const Gtk.Color & color () {
        return m_color;
    }


    /***********************************************************
    ***********************************************************/
    public QSize size_hint () override;
    public int height_for_width (int w) override;


    /***********************************************************
    Starts the spin animation.
    \sa on_stop_animation is_animated
    ***********************************************************/
    public void on_start_animation ();


    /***********************************************************
    Stops the spin animation.
    \sa on_start_animation is_animated
    ***********************************************************/
    public void on_stop_animation ();


    /***********************************************************
    Sets the delay between animation steps.
    Setting the \a delay to a value larger than 40 slows the animation, while setting the \a delay to a smaller value speeds it up.
    \param delay The delay, in milliseconds.
    \sa animation_delay
    ***********************************************************/
    public void on_set_animation_delay (int delay);


    /***********************************************************
    Sets whether the component hides itself when it is not animating.
    \param state The animation state. Set false to hide the progress indicator when it is not animating; otherwise true.
    \sa is_displayed_when_stopped
    ***********************************************************/
    public void on_set_displayed_when_stopped (bool state);


    /***********************************************************
    Sets the color of the components to the given color.
    \sa color
    ***********************************************************/
    public void on_set_color (Gtk.Color & color);

    protected void timer_event (QTimerEvent * event) override;
    protected void paint_event (QPaintEvent * event) override;

    /***********************************************************
    ***********************************************************/
    private int m_angle = 0;
    private int m_timer_id = -1;
    private int m_delay = 40;
    private bool m_displayed_when_stopped = false;
    private Gtk.Color m_color = Qt.black;
}










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

//  #include <QPainter>

QProgressIndicator.QProgressIndicator (Gtk.Widget* parent)
    : Gtk.Widget (parent) {
    set_size_policy (QSizePolicy.Fixed, QSizePolicy.Fixed);
    set_focus_policy (Qt.NoFocus);
}

bool QProgressIndicator.is_animated () {
    return (m_timer_id != -1);
}

void QProgressIndicator.on_set_displayed_when_stopped (bool state) {
    m_displayed_when_stopped = state;

    update ();
}

bool QProgressIndicator.is_displayed_when_stopped () {
    return m_displayed_when_stopped;
}

void QProgressIndicator.on_start_animation () {
    m_angle = 0;

    if (m_timer_id == -1)
        m_timer_id = start_timer (m_delay);
}

void QProgressIndicator.on_stop_animation () {
    if (m_timer_id != -1)
        kill_timer (m_timer_id);

    m_timer_id = -1;

    update ();
}

void QProgressIndicator.on_set_animation_delay (int delay) {
    if (m_timer_id != -1)
        kill_timer (m_timer_id);

    m_delay = delay;

    if (m_timer_id != -1)
        m_timer_id = start_timer (m_delay);
}

void QProgressIndicator.on_set_color (Gtk.Color & color) {
    m_color = color;

    update ();
}

QSize QProgressIndicator.size_hint () {
    return {20, 20};
}

int QProgressIndicator.height_for_width (int w) {
    return w;
}

void QProgressIndicator.timer_event (QTimerEvent * /*event*/) {
    m_angle = (m_angle+30)%360;

    update ();
}

void QProgressIndicator.paint_event (QPaintEvent * /*event*/) {
    if (!m_displayed_when_stopped && !is_animated ())
        return;

    int width = q_min (this.width (), this.height ());

    QPainter p (this);
    p.set_render_hint (QPainter.Antialiasing);

    int outer_radius = q_round ( (width - 1) * 0.5);
    int inner_radius = q_round ( (width - 1) * 0.5 * 0.38);

    int capsule_height = outer_radius - inner_radius;
    int capsule_width  = q_round ( (width > 32 ) ? capsule_height * 0.23 : capsule_height * 0.35);
    int capsule_radius = capsule_width/2;

    for (int i=0; i<12; i++) {
        Gtk.Color color = m_color;
        color.set_alpha_f (1.0f - (static_cast<float> (i) / 12.0f));
        p.set_pen (Qt.NoPen);
        p.set_brush (color);
        p.save ();
        p.translate (rect ().center ());
        p.rotate (m_angle - i * 30);
        p.draw_rounded_rect (q_round (-capsule_width * 0.5), - (inner_radius + capsule_height), capsule_width, capsule_height, capsule_radius, capsule_radius);
        p.restore ();
    }
}
