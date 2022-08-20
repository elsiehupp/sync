/***********************************************************
@class KirigamiWheelEvent

@brief Describes the mouse wheel event

@author 2019 Marco Martin <mart@kde.org>

@copyright LGPL 2.0 or later
***********************************************************/
public class KirigamiWheelEvent { //: GLib.Object {

//    /***********************************************************
//    ***********************************************************/
//    private double m_x = 0;
//    private double m_y = 0;
//    private GLib.PointF m_angle_delta;
//    private GLib.PointF m_pixel_delta;
//    private GLib.MouseButtons m_buttons = GLib.NoButton;
//    private GLib.KeyboardModifiers m_modifiers = GLib.NoModifier;
//    private bool m_inverted = false;
//    private bool m_accepted = false;

//    /***********************************************************
//    x : double

//    X coordinate of the mouse pointer
//    ***********************************************************/
//    //  Q_PROPERTY (double x READ x CONSTANT)

//    /***********************************************************
//    y : double

//    Y coordinate of the mouse pointer
//    ***********************************************************/
//    //  Q_PROPERTY (double y READ y CONSTANT)

//    /***********************************************************
//    angle_delta : point

//    The distance the wheel is rotated in degrees.
//    The x and y coordinates indicate the horizontal and vertical wheels respe
//    A positive value indicates it was rotated up/right, negative, bottom/left
//    This value is more likely to be set in traditional mice.
//    ***********************************************************/
//    //  Q_PROPERTY (GLib.PointF angle_delta READ angle_delta CONSTANT)

//    /***********************************************************
//    pixel_delta : point

//    provides the delta in screen pixels available on high resolution trackpads
//    ***********************************************************/
//    //  Q_PROPERTY (GLib.PointF pixel_delta READ pixel_delta CONSTANT)

//    /***********************************************************
//    buttons : int

//    it contains an OR combination of the buttons that were pressed during the wheel, they can be:
//    GLib.LeftButton, GLib.MiddleButton, GLib.RightButton
//    ***********************************************************/
//    //  Q_PROPERTY (int buttons READ buttons CONSTANT)

//    /***********************************************************
//    modifiers : int

//    Keyboard mobifiers that were pressed
//    GLib.NoModifier (def
//    GLib.ControlModifi
//    GLib.ShiftModifier
//    ...
//    ***********************************************************/
//    //  Q_PROPERTY (int modifiers READ modifiers CONSTANT)

//    /***********************************************************
//    inverted : bool

//    Whether the delta values are inverted
//    On some platformsthe returned delta are inverted, so positive values would mean bottom/left
//    ***********************************************************/
//    //  Q_PROPERTY (bool inverted READ inverted CONSTANT)

//    /***********************************************************
//    accepted : bool

//    If set, the event shouldn't be managed anymore,
//    for i
//    @code
//    // This handler handles automatically the scroll of
//    // flickable_item, unless Ctrl is pressed, in this c
//    // app has custom code
//    Kirigami.WheelHandler {
//      target : flickable_item
//      block_target_wheel : true
//      scroll_flick
//      on_wheel: {
//           if (wheel.modifiers & GLib.C
//               wheel.accepted = true;



//    }
//    @endcode

//    ***********************************************************/
//    //  Q_PROPERTY (bool accepted READ is_accepted WRITE set_accepted)


//    /***********************************************************
//    ***********************************************************/
//    public KirigamiWheelEvent (GLib.Object parent = new GLib.Object ()) {
//        base (parent);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void initialize_from_event (Gdk.EventScroll event) {
//        m_x = event.position ().x ();
//        m_y = event.position ().y ();
//        m_angle_delta = event.angle_delta ();
//        m_pixel_delta = event.pixel_delta ();
//        m_buttons = event.buttons ();
//        m_modifiers = event.modifiers ();
//        m_accepted = false;
//        m_inverted = event.inverted ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    public double x () {
//        return m_x;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public double y () {
//        return m_y;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public GLib.PointF angle_delta () {
//        return m_angle_delta;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public GLib.PointF pixel_delta () {
//        return m_pixel_delta;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public int buttons () {
//        return m_buttons;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public int modifiers () {
//        return m_modifiers;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public bool inverted () {
//        return m_inverted;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public bool is_accepted () {
//        return m_accepted;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void set_accepted (bool accepted) {
//        m_accepted = accepted;
//    }

}
