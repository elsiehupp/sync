/***********************************************************
@class GLib.ProgressIndicator

@brief The GLib.ProgressIndicator class lets an application
display a progress indicator to show that a lengthy task is
under way.

@details Progress indicators are indeterminate and do
nothing more than spin to show that the application is busy.

@author 2011 Morgan Leborgne

@copyright The MIT License (MIT)

@see GLib.ProgressBar
***********************************************************/
public class GLib.ProgressIndicator { //: Gtk.Widget {

    //  Q_PROPERTY (int delay READ animation_delay WRITE on_set_animation_delay)
    //  Q_PROPERTY (bool displayed_when_stopped READ is_displayed_when_stopped WRITE on_set_displayed_when_stopped)
    //  Q_PROPERTY (Gdk.RGBA color READ color WRITE on_set_color)

    /***********************************************************
    ***********************************************************/
    private int m_angle = 0;
    private int m_timer_id = -1;
    private int m_delay = 40;
    private bool m_displayed_when_stopped = false;
    private Gdk.RGBA m_color = GLib.black;

    /***********************************************************
    ***********************************************************/
    public GLib.ProgressIndicator (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base ();
        //  set_size_policy (GLib.SizePolicy.Fixed, GLib.SizePolicy.Fixed);
        //  set_focus_policy (GLib.NoFocus);
    }


    /***********************************************************
    Returns the delay between animation steps.
    \return The number of milliseconds between animation steps. By default, the animation delay is set to 40 milliseconds.
    \sa on_set_animation_delay
    ***********************************************************/
    public int animation_delay () {
        //  return m_delay;
    }


    /***********************************************************
    Returns a Boolean value indicating whether the component is currently animated.
    \return Animation state.
    \sa on_start_animation on_stop_animation
    ***********************************************************/
    public bool is_animated () {
        //  return m_timer_id != -1;
    }


    /***********************************************************
    Returns a Boolean value indicating whether the receiver shows itself even when it is not animating.
    \return Return true if the progress indicator shows itself even when it is not animating. By default, it returns false.
    \sa on_set_displayed_when_stopped
    ***********************************************************/
    public bool is_displayed_when_stopped () {
        //  return m_displayed_when_stopped;
    }


    /***********************************************************
    Returns the color of the component.
    \sa on_set_color
    ***********************************************************/
    public Gdk.RGBA color () {
        //  return m_color;
    }


    /***********************************************************
    ***********************************************************/
    public override Gdk.Rectangle size_hint () {
        //  return Gdk.Rectangle (20, 20);
    }


    /***********************************************************
    ***********************************************************/
    public override int height_for_width (int pixel_width) {
        //  return pixel_width;
    }


    /***********************************************************
    Starts the spin animation.
    \sa on_stop_animation is_animated
    ***********************************************************/
    public void on_start_animation () {
        //  m_angle = 0;
        //  if (m_timer_id == -1) {
        //      m_timer_id = start_timer (m_delay);
        //  }
    }


    /***********************************************************
    Stops the spin animation.
    \sa on_start_animation is_animated
    ***********************************************************/
    public void on_stop_animation () {
        //  if (m_timer_id != -1) {
        //      kill_timer (m_timer_id);
        //  }
        //  m_timer_id = -1;
        //  update ();
    }


    /***********************************************************
    Sets the delay between animation steps.
    Setting the \a delay to a value larger than 40 slows the animation, while setting the \a delay to a smaller value speeds it up.
    \param delay The delay, in milliseconds.
    \sa animation_delay
    ***********************************************************/
    public void on_set_animation_delay (int delay) {
        //  if (m_timer_id != -1) {
        //      kill_timer (m_timer_id);
        //  }
        //  m_delay = delay;
        //  if (m_timer_id != -1) {
        //      m_timer_id = start_timer (m_delay);
        //  }
    }


    /***********************************************************
    Sets whether the component hides itself when it is not animating.
    \param state The animation state. Set false to hide the progress indicator when it is not animating; otherwise true.
    \sa is_displayed_when_stopped
    ***********************************************************/
    public void on_set_displayed_when_stopped (bool state) {
        //  m_displayed_when_stopped = state;

        //  update ();
    }


    /***********************************************************
    Sets the color of the components to the given color.
    \sa color
    ***********************************************************/
    public void on_set_color (Gdk.RGBA color) {
        //  m_color = color;

        //  update ();
    }


    /***********************************************************
    ***********************************************************/
    protected override void timer_event (GLib.TimerEvent event) {
        //  m_angle = (m_angle+30)%360;

        //  update ();
    }


    /***********************************************************
    ***********************************************************/
    protected override void paint_event (GLib.PaintEvent event) {
        //  if (!m_displayed_when_stopped && !is_animated ()) {
        //      return;
        //  }

        //  int width = int.min (this.width (), this.height ());

        //  GLib.Painter p = new GLib.Painter (this);
        //  p.set_render_hint (GLib.Painter.Antialiasing);

        //  int outer_radius = q_round ( (width - 1) * 0.5);
        //  int inner_radius = q_round ( (width - 1) * 0.5 * 0.38);

        //  int capsule_height = outer_radius - inner_radius;
        //  int capsule_width  = q_round ( (width > 32 ) ? capsule_height * 0.23 : capsule_height * 0.35);
        //  int capsule_radius = capsule_width/2;

        //  for (int i=0; i<12; i++) {
        //      Gdk.RGBA color = m_color;
        //      color.set_alpha_f (1.0f - ((float)i / 12.0f));
        //      p.set_pen (GLib.NoPen);
        //      p.set_brush (color);
        //      p.save ();
        //      p.translate (rect ().center ());
        //      p.rotate (m_angle - i * 30);
        //      p.draw_rounded_rect (q_round (-capsule_width * 0.5), - (inner_radius + capsule_height), capsule_width, capsule_height, capsule_radius, capsule_radius);
        //      p.restore ();
        //  }
    }

}























