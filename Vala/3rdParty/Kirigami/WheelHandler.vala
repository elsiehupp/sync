/***********************************************************
SPDX-File_copyright_text : 2019 Marco Martin <mart@kde.org>

SPDX-License-Identifier : LGPL-2.0-or-later
***********************************************************/

// #pragma once

// #include <Qt_qml>
// #include <QPoint>
// #include <QQuick_item>
// #include <QWheel_event>
// #include <QQuick_item>
// #include <QDebug>

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


    /***********************************************************
    ***********************************************************/
    public WheelHandler (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void set_target (QQuick_item target);

signals:
    void target_changed ();
    void block_target_wheel_changed ();
    void scroll_flickable_target_changed ();
    void wheel (KirigamiWheelEvent wheel);


    /***********************************************************
    ***********************************************************/
    private QPointer<QQuick_item> m_target;
    private bool m_block_target_wheel = true;
    private bool m_scroll_flickable_target = true;
    private KirigamiWheelEvent m_wheel_event;

    /***********************************************************
    ***********************************************************/
    private friend class GlobalWheelFilter;
}


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

        /* emit */ target_changed ();
    }

    #include "moc_wheelhandler.cpp"
    