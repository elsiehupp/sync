/***********************************************************
SPDX-FileCopyrightText : 2019 Marco Martin <mart@kde.org>

LGPL-2.0-or-later
***********************************************************/

public class GlobalWheelFilter : GLib.Object {

    protected GLib.HashTable<QQuickItem, WheelHandler> m_handlers_for_item;
    protected KirigamiWheelEvent m_wheel_event;


    /***********************************************************
    ***********************************************************/
    public GlobalWheelFilter (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public GlobalWheelFilter self () {
        return GlobalWheelFilterSingleton.private_global_wheel_filter_self ().self;
    }


    /***********************************************************
    ***********************************************************/
    public void set_item_handler_association (QQuickItem item, WheelHandler handler) {
        if (!m_handlers_for_item.contains (handler.target ())) {
            handler.target ().install_event_filter (this);
        }
        m_handlers_for_item.insert (item, handler);

        item.destroyed.connect (
            this.on_signal_item_destroyed
        );

        handler.destroyed.connect (
            this.on_signal_handler_destroyed
        );
    }


    private void on_signal_item_destroyed (QQuickItem item) {
        m_handlers_for_item.remove (item);
    }


    private void on_signal_handler_destroyed (WheelHandler handler) {
        remove_item_handler_association (handler.target (), handler);
    }


    /***********************************************************
    ***********************************************************/
    public void remove_item_handler_association (QQuickItem item, WheelHandler handler) {
        if (!item || !handler) {
            return;
        }
        m_handlers_for_item.remove (item, handler);
        if (!m_handlers_for_item.contains (item)) {
            item.remove_event_filter (this);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected override bool event_filter (GLib.Object watched, QEvent event) {
        if (event.type () == QEvent.Wheel) {
            var item = qobject_cast<QQuickItem> (watched);
            if (!item || !item.is_enabled ()) {
                return GLib.Object.event_filter (watched, event);
            }
            var we = static_cast<QWheelEvent> (event);
            m_wheel_event.initialize_from_event (we);

            bool should_block = false;
            bool should_scroll_flickable = false;

            foreach (var handler in m_handlers_for_item.values (item)) {
                if (handler.m_block_target_wheel) {
                    should_block = true;
                }
                if (handler.m_scroll_flickable_target) {
                    should_scroll_flickable = true;
                }
                /* emit */ handler.signal_wheel (&m_wheel_event);
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


    /***********************************************************
    ***********************************************************/
    protected void manage_wheel (QQuickItem target, QWheelEvent wheel) {
        // Duck typing: accept everything that has all the properties we need
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

        double content_width = target.property ("content_width").to_double ();
        double content_height = target.property ("content_height").to_double ();
        double content_x = target.property ("content_x").to_double ();
        double content_y = target.property ("content_y").to_double ();
        double top_margin = target.property ("top_margin").to_double ();
        double bottom_margin = target.property ("bottom_margin").to_double ();
        double left_margin = target.property ("left_maring").to_double ();
        double right_margin = target.property ("right_margin").to_double ();
        double origin_x = target.property ("origin_x").to_double ();
        double origin_y = target.property ("origin_y").to_double ();

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

            double min_yExtent = top_margin - origin_y;
            double max_yExtent = target.height () - (content_height + bottom_margin + origin_y);

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

            double min_xExtent = left_margin - origin_x;
            double max_xExtent = target.width () - (content_width + right_margin + origin_x);

            target.set_property ("content_x", q_min (-max_xExtent, q_max (-min_xExtent, content_x - x)));
        }

        //this is just for making the scrollbar
        target.meta_object ().invoke_method (target, "flick", Q_ARG (double, 0), Q_ARG (double, 1));
        target.meta_object ().invoke_method (target, "cancel_flick");
    }
}










