/***********************************************************
SPDX-FileCopyrightText : 2019 Marco Martin <mart@kde.org>

LGPL-2.0-or-later
***********************************************************/

/***********************************************************
Describes the mouse wheel event
***********************************************************/
public class KirigamiWheelEvent : GLib.Object {

    /***********************************************************
    x : real

    X coordinate of the mouse pointer
    ***********************************************************/
    //  Q_PROPERTY (qreal x READ x CONSTANT)

    /***********************************************************
    y : real

    Y coordinate of the mouse pointer
    ***********************************************************/
    //  Q_PROPERTY (qreal y READ y CONSTANT)

    /***********************************************************
    angle_delta : point

    The distance the wheel is rotated in degrees.
    The x and y coordinates indicate the horizontal and vertical wheels respe
    A positive value indicates it was rotated up/right, negative, bottom/left
    This value is more likely to be set in traditional mice.
    ***********************************************************/
    //  Q_PROPERTY (QPointF angle_delta READ angle_delta CONSTANT)

    /***********************************************************
    pixel_delta : point

    provides the delta in screen pixels available on high resolution trackpads
    ***********************************************************/
    //  Q_PROPERTY (QPointF pixel_delta READ pixel_delta CONSTANT)

    /***********************************************************
    buttons : int

    it contains an OR combination of the buttons that were pressed during the wheel, they can be:
    Qt.LeftButton, Qt.MiddleButton, Qt.RightButton
    ***********************************************************/
    //  Q_PROPERTY (int buttons READ buttons CONSTANT)

    /***********************************************************
    modifiers : int

    Keyboard mobifiers that were pressed
    Qt.NoModifier (def
    Qt.ControlModifi
    Qt.ShiftModifier
    ...
    ***********************************************************/
    //  Q_PROPERTY (int modifiers READ modifiers CONSTANT)

    /***********************************************************
    inverted : bool

    Whether the delta values are inverted
    On some platformsthe returned delta are inverted, so positive values would mean bottom/left
    ***********************************************************/
    //  Q_PROPERTY (bool inverted READ inverted CONSTANT)

    /***********************************************************
    accepted : bool

    If set, the event shouldn't be managed anymore,
    for i
    @code
    // This handler handles automatically the scroll of
    // flickable_item, unless Ctrl is pressed, in this c
    // app has custom code
    Kirigami.WheelHandler {
      target : flickable_item
      block_target_wheel : true
      scroll_flick
      on_wheel: {
           if (wheel.modifiers & Qt.C
               wheel.accepted = true;



    }
    @endcode

    ***********************************************************/
    //  Q_PROPERTY (bool accepted READ is_accepted WRITE set_accepted)


    /***********************************************************
    ***********************************************************/
    public KirigamiWheelEvent (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public qreal y ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public QPointF pixel_del

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int modifiers ();


    public bool inverted ();


    public bool is_accepted ();


    public void set_accepted (bool accepted);


    /***********************************************************
    ***********************************************************/
    private qreal m_x = 0;
    private qreal m_y = 0;
    private QPointF m_angle_delta;
    private QPointF m_pixel_delta;
    private Qt.MouseButtons m_buttons = Qt.NoButton;
    private Qt.KeyboardModifiers m_modifiers = Qt.NoModifier;
    private bool m_inverted = false;
    private bool m_accepted = false;
}







    KirigamiWheelEvent.KirigamiWheelEvent (GLib.Object parent) {
        base (parent);}

    KirigamiWheelEvent.~KirigamiWheelEvent () = default;

    void KirigamiWheelEvent.initialize_from_event (QWheelEvent event) {
        m_x = event.position ().x ();
        m_y = event.position ().y ();
        m_angle_delta = event.angle_delta ();
        m_pixel_delta = event.pixel_delta ();
        m_buttons = event.buttons ();
        m_modifiers = event.modifiers ();
        m_accepted = false;
        m_inverted = event.inverted ();
    }

    qreal KirigamiWheelEvent.x () {
        return m_x;
    }

    qreal KirigamiWheelEvent.y () {
        return m_y;
    }

    QPointF KirigamiWheelEvent.angle_delta () {
        return m_angle_delta;
    }

    QPointF KirigamiWheelEvent.pixel_delta () {
        return m_pixel_delta;
    }

    int KirigamiWheelEvent.buttons () {
        return m_buttons;
    }

    int KirigamiWheelEvent.modifiers () {
        return m_modifiers;
    }

    bool KirigamiWheelEvent.inverted () {
        return m_inverted;
    }

    bool KirigamiWheelEvent.is_accepted () {
        return m_accepted;
    }

    void KirigamiWheelEvent.set_accepted (bool accepted) {
        m_accepted = accepted;
    }