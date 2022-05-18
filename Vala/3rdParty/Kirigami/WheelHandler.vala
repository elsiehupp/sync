/***********************************************************
@class WheelHandler

@details This class intercepts the mouse wheel events of its
target, and gives them to the user code as a signal, which
can be used for custom mouse wheel management code. The
handler can block completely the wheel events from its
target, and if it's a Flickable, it can automatically handle
scrolling on it.

@author 2019 Marco Martin <mart@kde.org>

@copyright LGPL 2.0 or later
***********************************************************/
public class WheelHandler : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private GLib.QuickItem m_target;
    private bool m_block_target_wheel = true;
    private bool m_scroll_flickable_target = true;
    private KirigamiWheelEvent m_wheel_event;

    /***********************************************************
    ***********************************************************/
    //  private friend class GlobalWheelFilter;

    internal signal void signal_target_changed ();
    internal signal void signal_block_target_wheel_changed ();
    internal signal void signal_scroll_flickable_target_changed ();
    internal signal void signal_wheel (KirigamiWheelEvent wheel);

    /***********************************************************
    target : Item

    The target we want to manage wheel events.
    We will receive signal_wheel () signals every time the user
    the mouse signal_wheel (or scrolls with the touchpad) on top
    of that item.
    ***********************************************************/
    //  Q_PROPERTY (GLib.QuickItem target READ target WRITE set_target NOTIFY signal_target_changed)

    /***********************************************************
    block_target_wheel : bool

    If true, the target won't receive any wheel event at all (default true)
    ***********************************************************/
    //  Q_PROPERTY (bool block_target_wheel MEMBER m_block_target_wheel NOTIFY signal_block_target_wheel_changed)

    /***********************************************************
    scroll_flickable_target : bool
    If this property is true and the target is a Flickable, wheel events will cause the Flickable to scroll (default true)
    ***********************************************************/
    //  Q_PROPERTY (bool scroll_flickable_target MEMBER m_scroll_flickable_target NOTIFY signal_scroll_flickable_target_changed)


    /***********************************************************
    ***********************************************************/
    public WheelHandler (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public GLib.QuickItem target () {
        return m_target;
    }


    /***********************************************************
    ***********************************************************/
    public void set_target (GLib.QuickItem target) {
        if (m_target == target) {
            return;
        }

        if (m_target) {
            GlobalWheelFilter.instance.remove_item_handler_association (m_target, this);
        }

        m_target = target;

        GlobalWheelFilter.instance.set_item_handler_association (target, this);

        signal_target_changed ();
    }

}
