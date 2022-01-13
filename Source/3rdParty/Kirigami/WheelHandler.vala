/***********************************************************
 SPDX-FileCopyrightText : 2019 Marco Martin <mart@kde.org>

 SPDX-License-Identifier : LGPL-2.0-or-later
***********************************************************/

// #pragma once

// #include <QtQml>
// #include <QPoint>
// #include <QQuickItem>
// #include <GLib.Object>



/***********************************************************
Describes the mouse wheel event
***********************************************************/
class KirigamiWheelEvent : GLib.Object {

    /***********************************************************
    x : real
    
     * X coordinate of the mouse pointer
    ***********************************************************/
    Q_PROPERTY (qreal x READ x CONSTANT)

    /***********************************************************
    y : real
    
     * Y coordinate of the mouse pointer
    ***********************************************************/
    Q_PROPERTY (qreal y READ y CONSTANT)

    /***********************************************************
    angleDelta : point
    
    The distance the wheel is rotated in degrees.
    The x and y coordinates indicate the horizontal and vertical wheels respe
    A positive value indicates it was rotated up/right, negative, bottom/left
     * This value is more likely to be set in traditional mice.
    ***********************************************************/
    Q_PROPERTY (QPointF angleDelta READ angleDelta CONSTANT)

    /***********************************************************
    pixelDelta : point
    
     * provides the delta in screen pixels available on high resolution trackpads
    ***********************************************************/
    Q_PROPERTY (QPointF pixelDelta READ pixelDelta CONSTANT)

    /***********************************************************
    buttons : int
    
    it contains an OR combination of the buttons that were pressed during the wheel, they can be:
     * Qt.LeftButton, Qt.MiddleButton, Qt.RightButton
    ***********************************************************/
    Q_PROPERTY (int buttons READ buttons CONSTANT)

    /***********************************************************
    modifiers : int
    
    Keyboard mobifiers that were pressed 
    Qt.NoModifier (def
    Qt.ControlModifi
    Qt.ShiftModifier
     * ...
    ***********************************************************/
    Q_PROPERTY (int modifiers READ modifiers CONSTANT)

    /***********************************************************
    inverted : bool
    
    Whether the delta values are inverted
     * On some platformsthe returned delta are inverted, so positive values would mean bottom/left
    ***********************************************************/
    Q_PROPERTY (bool inverted READ inverted CONSTANT)

    /***********************************************************
    accepted : bool
    
    If set, the event shouldn't be managed anymore,
    for i
    @code
    // This handler handles automatically the scroll of
    // flickableItem, unless Ctrl is pressed, in this c
    // app has custom code 
    Kirigami.WheelHandler {
      target : flickableItem
      blockTargetWheel : true
      scrollFlick
      onWheel : {
           if (wheel.modifiers & Qt.C
               wheel.accepted = true;
           
       
     
    }
     * @endcode

    ***********************************************************/
    Q_PROPERTY (bool accepted READ isAccepted WRITE setAccepted)

public:
    KirigamiWheelEvent (GLib.Object *parent = nullptr);
    ~KirigamiWheelEvent () override;

    void initializeFromEvent (QWheelEvent *event);

    qreal x ();
    qreal y ();
    QPointF angleDelta ();
    QPointF pixelDelta ();
    int buttons ();
    int modifiers ();
    bool inverted ();
    bool isAccepted ();
    void setAccepted (bool accepted);

private:
    qreal m_x = 0;
    qreal m_y = 0;
    QPointF m_angleDelta;
    QPointF m_pixelDelta;
    Qt.MouseButtons m_buttons = Qt.NoButton;
    Qt.KeyboardModifiers m_modifiers = Qt.NoModifier;
    bool m_inverted = false;
    bool m_accepted = false;
};

class GlobalWheelFilter : GLib.Object {

public:
    GlobalWheelFilter (GLib.Object *parent = nullptr);
    ~GlobalWheelFilter () override;

    static GlobalWheelFilter *self ();

    void setItemHandlerAssociation (QQuickItem *item, WheelHandler *handler);
    void removeItemHandlerAssociation (QQuickItem *item, WheelHandler *handler);

protected:
    bool eventFilter (GLib.Object *watched, QEvent *event) override;

private:
    void manageWheel (QQuickItem *target, QWheelEvent *wheel);

    QMultiHash<QQuickItem *, WheelHandler> m_handlersForItem;
    KirigamiWheelEvent m_wheelEvent;
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
     * of that item.
    ***********************************************************/
    Q_PROPERTY (QQuickItem *target READ target WRITE setTarget NOTIFY targetChanged)

    /***********************************************************
    blockTargetWheel : bool
    
     * If true, the target won't receive any wheel event at all (default true)
    ***********************************************************/
    Q_PROPERTY (bool blockTargetWheel MEMBER m_blockTargetWheel NOTIFY blockTargetWheelChanged)

    /***********************************************************
    scrollFlickableTarget : bool
    If this property is true and the target is a Flickable, wheel events will cause the Flickable to scroll (default true)
    ***********************************************************/
    Q_PROPERTY (bool scrollFlickableTarget MEMBER m_scrollFlickableTarget NOTIFY scrollFlickableTargetChanged)

public:
    WheelHandler (GLib.Object *parent = nullptr);
    ~WheelHandler () override;

    QQuickItem *target ();
    void setTarget (QQuickItem *target);

signals:
    void targetChanged ();
    void blockTargetWheelChanged ();
    void scrollFlickableTargetChanged ();
    void wheel (KirigamiWheelEvent *wheel);

private:
    QPointer<QQuickItem> m_target;
    bool m_blockTargetWheel = true;
    bool m_scrollFlickableTarget = true;
    KirigamiWheelEvent m_wheelEvent;

    friend class GlobalWheelFilter;
};











/***********************************************************
 SPDX-FileCopyrightText : 2019 Marco Martin <mart@kde.org>

 SPDX-License-Identifier : LGPL-2.0-or-later
***********************************************************/

// #include <QWheelEvent>
// #include <QQuickItem>
// #include <QDebug>

class GlobalWheelFilterSingleton {
    public:
        GlobalWheelFilter self;
    };
    
    Q_GLOBAL_STATIC (GlobalWheelFilterSingleton, privateGlobalWheelFilterSelf)
    
    GlobalWheelFilter.GlobalWheelFilter (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    GlobalWheelFilter.~GlobalWheelFilter () = default;
    
    GlobalWheelFilter *GlobalWheelFilter.self () {
        return &privateGlobalWheelFilterSelf ().self;
    }
    
    void GlobalWheelFilter.setItemHandlerAssociation (QQuickItem *item, WheelHandler *handler) {
        if (!m_handlersForItem.contains (handler.target ())) {
            handler.target ().installEventFilter (this);
        }
        m_handlersForItem.insert (item, handler);
    
        connect (item, &GLib.Object.destroyed, this, [this] (GLib.Object *obj) {
            auto item = static_cast<QQuickItem> (obj);
            m_handlersForItem.remove (item);
        });
    
        connect (handler, &GLib.Object.destroyed, this, [this] (GLib.Object *obj) {
            auto handler = static_cast<WheelHandler> (obj);
            removeItemHandlerAssociation (handler.target (), handler);
        });
    }
    
    void GlobalWheelFilter.removeItemHandlerAssociation (QQuickItem *item, WheelHandler *handler) {
        if (!item || !handler) {
            return;
        }
        m_handlersForItem.remove (item, handler);
        if (!m_handlersForItem.contains (item)) {
            item.removeEventFilter (this);
        }
    }
    
    bool GlobalWheelFilter.eventFilter (GLib.Object *watched, QEvent *event) {
        if (event.type () == QEvent.Wheel) {
            auto item = qobject_cast<QQuickItem> (watched);
            if (!item || !item.isEnabled ()) {
                return GLib.Object.eventFilter (watched, event);
            }
            auto we = static_cast<QWheelEvent> (event);
            m_wheelEvent.initializeFromEvent (we);
    
            bool shouldBlock = false;
            bool shouldScrollFlickable = false;
    
            for (auto *handler : m_handlersForItem.values (item)) {
                if (handler.m_blockTargetWheel) {
                    shouldBlock = true;
                }
                if (handler.m_scrollFlickableTarget) {
                    shouldScrollFlickable = true;
                }
                emit handler.wheel (&m_wheelEvent);
            }
    
            if (shouldScrollFlickable && !m_wheelEvent.isAccepted ()) {
                manageWheel (item, we);
            }
    
            if (shouldBlock) {
                return true;
            }
        }
        return GLib.Object.eventFilter (watched, event);
    }
    
    void GlobalWheelFilter.manageWheel (QQuickItem *target, QWheelEvent *event) {
        // Duck typing : accept everyhint that has all the properties we need
        if (target.metaObject ().indexOfProperty ("contentX") == -1
            || target.metaObject ().indexOfProperty ("contentY") == -1
            || target.metaObject ().indexOfProperty ("contentWidth") == -1
            || target.metaObject ().indexOfProperty ("contentHeight") == -1
            || target.metaObject ().indexOfProperty ("topMargin") == -1
            || target.metaObject ().indexOfProperty ("bottomMargin") == -1
            || target.metaObject ().indexOfProperty ("leftMargin") == -1
            || target.metaObject ().indexOfProperty ("rightMargin") == -1
            || target.metaObject ().indexOfProperty ("originX") == -1
            || target.metaObject ().indexOfProperty ("originY") == -1) {
            return;
        }
    
        qreal contentWidth = target.property ("contentWidth").toReal ();
        qreal contentHeight = target.property ("contentHeight").toReal ();
        qreal contentX = target.property ("contentX").toReal ();
        qreal contentY = target.property ("contentY").toReal ();
        qreal topMargin = target.property ("topMargin").toReal ();
        qreal bottomMargin = target.property ("bottomMargin").toReal ();
        qreal leftMargin = target.property ("leftMaring").toReal ();
        qreal rightMargin = target.property ("rightMargin").toReal ();
        qreal originX = target.property ("originX").toReal ();
        qreal originY = target.property ("originY").toReal ();
    
        // Scroll Y
        if (contentHeight > target.height ()) {
    
            int y = event.pixelDelta ().y () != 0 ? event.pixelDelta ().y () : event.angleDelta ().y () / 8;
    
            //if we don't have a pixeldelta, apply the configured mouse wheel lines
            if (!event.pixelDelta ().y ()) {
                y *= 3; // Magic copied value from Kirigami.Settings
            }
    
            // Scroll one page regardless of delta:
            if ( (event.modifiers () & Qt.ControlModifier) || (event.modifiers () & Qt.ShiftModifier)) {
                if (y > 0) {
                    y = target.height ();
                } else if (y < 0) {
                    y = -target.height ();
                }
            }
    
            qreal minYExtent = topMargin - originY;
            qreal maxYExtent = target.height () - (contentHeight + bottomMargin + originY);
    
            target.setProperty ("contentY", qMin (-maxYExtent, qMax (-minYExtent, contentY - y)));
        }
    
        //Scroll X
        if (contentWidth > target.width ()) {
    
            int x = event.pixelDelta ().x () != 0 ? event.pixelDelta ().x () : event.angleDelta ().x () / 8;
    
            // Special case : when can't scroll vertically, scroll horizontally with vertical wheel as well
            if (x == 0 && contentHeight <= target.height ()) {
                x = event.pixelDelta ().y () != 0 ? event.pixelDelta ().y () : event.angleDelta ().y () / 8;
            }
    
            //if we don't have a pixeldelta, apply the configured mouse wheel lines
            if (!event.pixelDelta ().x ()) {
                x *= 3; // Magic copied value from Kirigami.Settings
            }
    
            // Scroll one page regardless of delta:
            if ( (event.modifiers () & Qt.ControlModifier) || (event.modifiers () & Qt.ShiftModifier)) {
                if (x > 0) {
                    x = target.width ();
                } else if (x < 0) {
                    x = -target.width ();
                }
            }
    
            qreal minXExtent = leftMargin - originX;
            qreal maxXExtent = target.width () - (contentWidth + rightMargin + originX);
    
            target.setProperty ("contentX", qMin (-maxXExtent, qMax (-minXExtent, contentX - x)));
        }
    
        //this is just for making the scrollbar
        target.metaObject ().invokeMethod (target, "flick", Q_ARG (double, 0), Q_ARG (double, 1));
        target.metaObject ().invokeMethod (target, "cancelFlick");
    }
    
    ////////////////////////////
    KirigamiWheelEvent.KirigamiWheelEvent (GLib.Object *parent)
        : GLib.Object (parent) {}
    
    KirigamiWheelEvent.~KirigamiWheelEvent () = default;
    
    void KirigamiWheelEvent.initializeFromEvent (QWheelEvent *event) {
        m_x = event.position ().x ();
        m_y = event.position ().y ();
        m_angleDelta = event.angleDelta ();
        m_pixelDelta = event.pixelDelta ();
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
    
    QPointF KirigamiWheelEvent.angleDelta () {
        return m_angleDelta;
    }
    
    QPointF KirigamiWheelEvent.pixelDelta () {
        return m_pixelDelta;
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
    
    bool KirigamiWheelEvent.isAccepted () {
        return m_accepted;
    }
    
    void KirigamiWheelEvent.setAccepted (bool accepted) {
        m_accepted = accepted;
    }
    
    ///////////////////////////////
    
    WheelHandler.WheelHandler (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    WheelHandler.~WheelHandler () = default;
    
    QQuickItem *WheelHandler.target () {
        return m_target;
    }
    
    void WheelHandler.setTarget (QQuickItem *target) {
        if (m_target == target) {
            return;
        }
    
        if (m_target) {
            GlobalWheelFilter.self ().removeItemHandlerAssociation (m_target, this);
        }
    
        m_target = target;
    
        GlobalWheelFilter.self ().setItemHandlerAssociation (target, this);
    
        emit targetChanged ();
    }
    
    #include "moc_wheelhandler.cpp"
    