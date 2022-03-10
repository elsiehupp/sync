/***********************************************************
SPDX-FileCopyrightText : 2019 Marco Martin <mart@kde.org>

LGPL-2.0-or-later
***********************************************************/

class GlobalWheelFilter : GLib.Object {


    /***********************************************************
    ***********************************************************/
    public GlobalWheelFilter (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void remove_item_handler_association (QQuickItem item, WheelHandler handler);


    protected bool event_filter (GLib.Object watched, QEvent event) override;

    protected private void manage_wheel (QQuickItem target, QWheelEvent wheel);

    protected private QMultiHash<QQuickItem *, WheelHandler> m_handlers_for_item;
    protected private KirigamiWheelEvent m_wheel_event;
}




    Q_GLOBAL_STATIC (GlobalWheelFilterSingleton, private_global_wheel_filter_self)

    GlobalWheelFilter.GlobalWheelFilter (GLib.Object parent) {
        base (parent);
    }

    GlobalWheelFilter.~GlobalWheelFilter () = default;

    GlobalWheelFilter *GlobalWheelFilter.self () {
        return private_global_wheel_filter_self ().self;
    }

    void GlobalWheelFilter.set_item_handler_association (QQuickItem item, WheelHandler handler) {
        if (!m_handlers_for_item.contains (handler.target ())) {
            handler.target ().install_event_filter (this);
        }
        m_handlers_for_item.insert (item, handler);

        connect (item, &GLib.Object.destroyed, this, [this] (GLib.Object object) {
            var item = static_cast<QQuickItem> (object);
            m_handlers_for_item.remove (item);
        });

        connect (handler, &GLib.Object.destroyed, this, [this] (GLib.Object object) {
            var handler = static_cast<WheelHandler> (object);
            remove_item_handler_association (handler.target (), handler);
        });
    }

    void GlobalWheelFilter.remove_item_handler_association (QQuickItem item, WheelHandler handler) {
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
            var item = qobject_cast<QQuickItem> (watched);
            if (!item || !item.is_enabled ()) {
                return GLib.Object.event_filter (watched, event);
            }
            var we = static_cast<QWheelEvent> (event);
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
                /* emit */ handler.wheel (&m_wheel_event);
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

    void GlobalWheelFilter.manage_wheel (QQuickItem target, QWheelEvent event) {
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
            if ( (event.modifiers () & Qt.ControlModifier) || (event.modifiers () & Qt.ShiftModifier)) {
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
            if ( (event.modifiers () & Qt.ControlModifier) || (event.modifiers () & Qt.ShiftModifier)) {
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