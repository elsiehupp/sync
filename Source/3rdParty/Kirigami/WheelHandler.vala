/***********************************************************
 SPDX-File_copyright_text : 2019 Marco Martin <mart@kde.org>

 SPDX-License-Identifier : LGPL-2.0-or-later
***********************************************************/

// #pragma once

// #include <Qt_qml>
// #include <QPoint>
// #include <QQuick_item>



/***********************************************************
Describes the mouse wheel event
***********************************************************/
class KirigamiWheelEvent : GLib.Object {

    /***********************************************************
    x : real

    X coordinate of the mouse pointer
    ***********************************************************/
    Q_PROPERTY (qreal x READ x CONSTANT)

    /***********************************************************
    y : real

    Y coordinate of the mouse pointer
    ***********************************************************/
    Q_PROPERTY (qreal y READ y CONSTANT)

    /***********************************************************
    angle_delta : point

    The distance the wheel is rotated in degrees.
    The x and y coordinates indicate the horizontal and vertical wheels respe
    A positive value indicates it was rotated up/right, negative, bottom/left
    This value is more likely to be set in traditional mice.
    ***********************************************************/
    Q_PROPERTY (QPoint_f angle_delta READ angle_delta CONSTANT)

    /***********************************************************
    pixel_delta : point

    provides the delta in screen pixels available on high resolution trackpads
    ***********************************************************/
    Q_PROPERTY (QPoint_f pixel_delta READ pixel_delta CONSTANT)

    /***********************************************************
    buttons : int

    it contains an OR combination of the buttons that were pressed during the wheel, they can be:
    Qt.Left_button, Qt.Middle_button, Qt.Right_button
    ***********************************************************/
    Q_PROPERTY (int buttons READ buttons CONSTANT)

    /***********************************************************
    modifiers : int

    Keyboard mobifiers that were pressed
    Qt.No_modifier (def
    Qt.Control_modifi
    Qt.Shift_modifier
    ...
    ***********************************************************/
    Q_PROPERTY (int modifiers READ modifiers CONSTANT)

    /***********************************************************
    inverted : bool

    Whether the delta values are inverted
    On some platformsthe returned delta are inverted, so positive values would mean bottom/left
    ***********************************************************/
    Q_PROPERTY (bool inverted READ inverted CONSTANT)

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
    Q_PROPERTY (bool accepted READ is_accepted WRITE set_accepted)


    public KirigamiWheelEvent (GLib.Object parent = nullptr);
    ~KirigamiWheelEvent () override;

    public void initialize_from_event (QWheel_event event);

    public qreal x ();


    public qreal y ();


    public QPoint_f angle_delta ();


    public QPoint_f pixel_delta ();


    public int buttons ();


    public int modifiers ();


    public bool inverted ();


    public bool is_accepted ();


    public void set_accepted (bool accepted);


    private qreal m_x = 0;
    private qreal m_y = 0;
    private QPoint_f m_angle_delta;
    private QPoint_f m_pixel_delta;
    private Qt.Mouse_buttons m_buttons = Qt.NoButton;
    private Qt.Keyboard_modifiers m_modifiers = Qt.No_modifier;
    private bool m_inverted = false;
    private bool m_accepted = false;
};

class GlobalWheelFilter : GLib.Object {


    public GlobalWheelFilter (GLib.Object parent = nullptr);
    ~GlobalWheelFilter () override;

    public static GlobalWheelFilter self ();

    public void set_item_handler_association (QQuick_item item, WheelHandler handler);


    public void remove_item_handler_association (QQuick_item item, WheelHandler handler);


    protected bool event_filter (GLib.Object watched, QEvent event) override;

    protected private void manage_wheel (QQuick_item target, QWheel_event wheel);

    protected private QMulti_hash<QQuick_item *, WheelHandler> m_handlers_for_item;
    protected private KirigamiWheelEvent m_wheel_event;
};

/***********************************************************
This class intercepts the mouse wheel events of its target, and gives them to the user code as a signal, which can be used for custom mouse wheel management code.
The handler can block completely the wheel events from its target, and if it's a Flickable, it can automatically handle scrolling on it
***********************************************************/
class WheelHandler : GLib.Object {

    /***********************************************************
    target : Item

    The target we want to manage wheel events.
    We will receive wheel () signals every time the user
    the mouse wheel (or scrolls with the touchpad) on top
    of that item.
    ***********************************************************/
    Q_PROPERTY (QQuick_item target READ target WRITE set_target NOTIFY target_changed)

    /***********************************************************
    block_target_wheel : bool

    If true, the target won't receive any wheel event at all (default true)
    ***********************************************************/
    Q_PROPERTY (bool block_target_wheel MEMBER m_block_target_wheel NOTIFY block_target_wheel_changed)

    /***********************************************************
    scroll_flickable_target : bool
    If this property is true and the target is a Flickable, wheel events will cause the Flickable to scroll (default true)
    ***********************************************************/
    Q_PROPERTY (bool scroll_flickable_target MEMBER m_scroll_flickable_target NOTIFY scroll_flickable_target_changed)


    public WheelHandler (GLib.Object parent = nullptr);
    ~WheelHandler () override;

    public QQuick_item target ();


    public void set_target (QQuick_item target);

signals:
    void target_changed ();
    void block_target_wheel_changed ();
    void scroll_flickable_target_changed ();
    void wheel (KirigamiWheelEvent wheel);


    private QPointer<QQuick_item> m_target;
    private bool m_block_target_wheel = true;
    private bool m_scroll_flickable_target = true;
    private KirigamiWheelEvent m_wheel_event;

    private friend class GlobalWheelFilter;
};











/***********************************************************
 SPDX-File_copyright_text : 2019 Marco Martin <mart@kde.org>

 SPDX-License-Identifier : LGPL-2.0-or-later
***********************************************************/

// #include <QWheel_event>
// #include <QQuick_item>
// #include <QDebug>

class GlobalWheelFilter_singleton {
    public GlobalWheelFilter self;
};

    Q_GLOBAL_STATIC (GlobalWheelFilter_singleton, private_global_wheel_filter_self)

    GlobalWheelFilter.GlobalWheelFilter (GLib.Object parent) {
        base (parent);
    }

    GlobalWheelFilter.~GlobalWheelFilter () = default;

    GlobalWheelFilter *GlobalWheelFilter.self () {
        return &private_global_wheel_filter_self ().self;
    }

    void GlobalWheelFilter.set_item_handler_association (QQuick_item item, WheelHandler handler) {
        if (!m_handlers_for_item.contains (handler.target ())) {
            handler.target ().install_event_filter (this);
        }
        m_handlers_for_item.insert (item, handler);

        connect (item, &GLib.Object.destroyed, this, [this] (GLib.Object obj) {
            var item = static_cast<QQuick_item> (obj);
            m_handlers_for_item.remove (item);
        });

        connect (handler, &GLib.Object.destroyed, this, [this] (GLib.Object obj) {
            var handler = static_cast<WheelHandler> (obj);
            remove_item_handler_association (handler.target (), handler);
        });
    }

    void GlobalWheelFilter.remove_item_handler_association (QQuick_item item, WheelHandler handler) {
        if (!item || !handler) {
            return;
        }
        m_handlers_for_item.remove (item, handler);
        if (!m_handlers_for_item.contains (item)) {
            item.remove_event_filter (this);
        }
    }

    bool GlobalWheelFilter.event_filter (GLib.Object watched, QEvent event) {
        if (event.type () == QEvent.Wheel) {
            var item = qobject_cast<QQuick_item> (watched);
            if (!item || !item.is_enabled ()) {
                return GLib.Object.event_filter (watched, event);
            }
            var we = static_cast<QWheel_event> (event);
            m_wheel_event.initialize_from_event (we);

            bool should_block = false;
            bool should_scroll_flickable = false;

            for (var handler : m_handlers_for_item.values (item)) {
                if (handler.m_block_target_wheel) {
                    should_block = true;
                }
                if (handler.m_scroll_flickable_target) {
                    should_scroll_flickable = true;
                }
                emit handler.wheel (&m_wheel_event);
            }

            if (should_scroll_flickable && !m_wheel_event.is_accepted ()) {
                manage_wheel (item, we);
            }

            if (should_block) {
                return true;
            }
        }
        return GLib.Object.event_filter (watched, event);
    }

    void GlobalWheelFilter.manage_wheel (QQuick_item target, QWheel_event event) {
        // Duck typing : accept everyhint that has all the properties we need
        if (target.meta_object ().index_of_property ("content_x") == -1
            || target.meta_object ().index_of_property ("content_y") == -1
            || target.meta_object ().index_of_property ("content_width") == -1
            || target.meta_object ().index_of_property ("content_height") == -1
            || target.meta_object ().index_of_property ("top_margin") == -1
            || target.meta_object ().index_of_property ("bottom_margin") == -1
            || target.meta_object ().index_of_property ("left_margin") == -1
            || target.meta_object ().index_of_property ("right_margin") == -1
            || target.meta_object ().index_of_property ("origin_x") == -1
            || target.meta_object ().index_of_property ("origin_y") == -1) {
            return;
        }

        qreal content_width = target.property ("content_width").to_real ();
        qreal content_height = target.property ("content_height").to_real ();
        qreal content_x = target.property ("content_x").to_real ();
        qreal content_y = target.property ("content_y").to_real ();
        qreal top_margin = target.property ("top_margin").to_real ();
        qreal bottom_margin = target.property ("bottom_margin").to_real ();
        qreal left_margin = target.property ("left_maring").to_real ();
        qreal right_margin = target.property ("right_margin").to_real ();
        qreal origin_x = target.property ("origin_x").to_real ();
        qreal origin_y = target.property ("origin_y").to_real ();

        // Scroll Y
        if (content_height > target.height ()) {

            int y = event.pixel_delta ().y () != 0 ? event.pixel_delta ().y () : event.angle_delta ().y () / 8;

            //if we don't have a pixeldelta, apply the configured mouse wheel lines
            if (!event.pixel_delta ().y ()) {
                y *= 3; // Magic copied value from Kirigami.Settings
            }

            // Scroll one page regardless of delta:
            if ( (event.modifiers () & Qt.Control_modifier) || (event.modifiers () & Qt.Shift_modifier)) {
                if (y > 0) {
                    y = target.height ();
                } else if (y < 0) {
                    y = -target.height ();
                }
            }

            qreal min_yExtent = top_margin - origin_y;
            qreal max_yExtent = target.height () - (content_height + bottom_margin + origin_y);

            target.set_property ("content_y", q_min (-max_yExtent, q_max (-min_yExtent, content_y - y)));
        }

        //Scroll X
        if (content_width > target.width ()) {

            int x = event.pixel_delta ().x () != 0 ? event.pixel_delta ().x () : event.angle_delta ().x () / 8;

            // Special case : when can't scroll vertically, scroll horizontally with vertical wheel as well
            if (x == 0 && content_height <= target.height ()) {
                x = event.pixel_delta ().y () != 0 ? event.pixel_delta ().y () : event.angle_delta ().y () / 8;
            }

            //if we don't have a pixeldelta, apply the configured mouse wheel lines
            if (!event.pixel_delta ().x ()) {
                x *= 3; // Magic copied value from Kirigami.Settings
            }

            // Scroll one page regardless of delta:
            if ( (event.modifiers () & Qt.Control_modifier) || (event.modifiers () & Qt.Shift_modifier)) {
                if (x > 0) {
                    x = target.width ();
                } else if (x < 0) {
                    x = -target.width ();
                }
            }

            qreal min_xExtent = left_margin - origin_x;
            qreal max_xExtent = target.width () - (content_width + right_margin + origin_x);

            target.set_property ("content_x", q_min (-max_xExtent, q_max (-min_xExtent, content_x - x)));
        }

        //this is just for making the scrollbar
        target.meta_object ().invoke_method (target, "flick", Q_ARG (double, 0), Q_ARG (double, 1));
        target.meta_object ().invoke_method (target, "cancel_flick");
    }

    ////////////////////////////
    KirigamiWheelEvent.KirigamiWheelEvent (GLib.Object parent) {
        base (parent);}

    KirigamiWheelEvent.~KirigamiWheelEvent () = default;

    void KirigamiWheelEvent.initialize_from_event (QWheel_event event) {
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

    QPoint_f KirigamiWheelEvent.angle_delta () {
        return m_angle_delta;
    }

    QPoint_f KirigamiWheelEvent.pixel_delta () {
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

    ///////////////////////////////

    WheelHandler.WheelHandler (GLib.Object parent) {
        base (parent);
    }

    WheelHandler.~WheelHandler () = default;

    QQuick_item *WheelHandler.target () {
        return m_target;
    }

    void WheelHandler.set_target (QQuick_item target) {
        if (m_target == target) {
            return;
        }

        if (m_target) {
            GlobalWheelFilter.self ().remove_item_handler_association (m_target, this);
        }

        m_target = target;

        GlobalWheelFilter.self ().set_item_handler_association (target, this);

        emit target_changed ();
    }

    #include "moc_wheelhandler.cpp"
    