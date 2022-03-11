/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QGuiApplication>
//  #include <QMouseEvent>
//  #include <QPainter>
//  #include <QStyle>
//  #include <QStyle_hints>
//  const int HASQT5_11 (QT_VERSION >= QT_VERSION_CHECK (5,11,0))
//  #include <Gtk.Widget>
//  #include <QBasic_timer>
//  #include <QPointer>
//  #include <QVariantAnimation>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SlideShow class
@ingroup gui
***********************************************************/
class SlideShow : Gtk.Widget {

    const int SPACING = 6;
    const int SLIDE_DURATION = 1000;
    const int SLIDE_DISTANCE = 400;

    /***********************************************************
    ***********************************************************/
    private bool reverse = false;
    private int interval = 3500;
    private int current_index = 0;
    private QPoint press_point;
    private QBasic_timer timer;
    private string[] labels;
    private GLib.Vector<QPixmap> pixmaps;
    private QPointer<QVariantAnimation> animation = null;

    signal void clicked ();
    signal void current_slide_changed (int index);

    /***********************************************************
    ***********************************************************/
    public SlideShow (Gtk.Widget parent = null) {
        base (parent);
        this.size_policy (QSizePolicy.Minimum, QSizePolicy.Minimum);
    }


    /***********************************************************
    ***********************************************************/
    public void add_slide (QPixmap pixmap, string label) {
        this.labels += label;
        this.pixmaps += pixmap;
        update_geometry ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_active () {
        return this.timer.is_active ();
    }


    /***********************************************************
    ***********************************************************/
    public int interval () {
        return this.interval;
    }


    /***********************************************************
    ***********************************************************/
    public void interval (int interval) {
        if (this.interval == interval)
            return;

        this.interval = interval;
        maybe_restart_timer ();
    }


    /***********************************************************
    ***********************************************************/
    public void draw_slide (QPainter painter, int index) {
        string label = this.labels.value (index);
        QRect label_rect = style ().item_text_rect (font_metrics (), rect (), Qt.Align_bottom | Qt.AlignHCenter, is_enabled (), label);
        style ().draw_item_text (painter, label_rect, Qt.AlignCenter, palette (), is_enabled (), label, QPalette.Window_text);

        QPixmap pixmap = this.pixmaps.value (index);
        QRect pixmap_rect = style ().item_pixmap_rect (QRect (0, 0, width (), label_rect.top () - SPACING), Qt.AlignCenter, pixmap);
        style ().draw_item_pixmap (painter, pixmap_rect, Qt.AlignCenter, pixmap);
    }


    /***********************************************************
    ***********************************************************/
    public int current_slide () {
        return this.current_index;
    }


    /***********************************************************
    ***********************************************************/
    public void current_slide (int index) {
        if (this.current_index == index)
            return;

        if (!this.animation) {
            this.animation = new QVariantAnimation (this);
            this.animation.duration (SLIDE_DURATION);
            this.animation.easing_curve (QEasing_curve.Out_cubic);
            this.animation.start_value (static_cast<qreal> (this.current_index));
            connect (this.animation.data (), SIGNAL (value_changed (GLib.Variant)), this, SLOT (update ()));
        }
        this.animation.end_value (static_cast<qreal> (index));
        this.animation.on_signal_start (QAbstractAnimation.DeleteWhenStopped);

        this.reverse = index < this.current_index;
        this.current_index = index;
        maybe_restart_timer ();
        update ();
        /* emit */ current_slide_changed (index);
    }


    /***********************************************************
    ***********************************************************/
    public QSize size_hint () {
        QFontMetrics font_metrics = font_metrics ();
        QSize label_size (0, font_metrics.height ());
        for (string label : this.labels) {
    //  #if (HASQT5_11)
            label_size.width (std.max (font_metrics.horizontal_advance (label), label_size.width ()));
    //  #else
    //          label_size.width (std.max (font_metrics.width (label), label_size.width ()));
    //  #endif
        }
        QSize pixmap_size;
        for (QPixmap pixmap : this.pixmaps) {
            pixmap_size.width (std.max (pixmap.width (), pixmap_size.width ()));
            pixmap_size.height (std.max (pixmap.height (), pixmap_size.height ()));
        }
        return {
            std.max (label_size.width (), pixmap_size.width ()),
            label_size.height () + SPACING + pixmap_size.height ()
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start_show (int interval) {
        if (interval > 0)
            this.interval = interval;
        this.timer.on_signal_start (this.interval, this);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_stop_show () {
        this.timer.stop ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_next_slide () {
        current_slide ( (this.current_index + 1) % this.labels.count ());
        this.reverse = false;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_prev_slide () {
        current_slide ( (this.current_index > 0 ? this.current_index : this.labels.count ()) - 1);
        this.reverse = true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_reset () {
        on_signal_stop_show ();
        this.pixmaps.clear ();
        this.labels.clear ();
        update_geometry ();
        update ();
    }


    /***********************************************************
    ***********************************************************/
    protected void mouse_press_event (QMouseEvent event) {
        this.press_point = event.position ();
    }


    /***********************************************************
    ***********************************************************/
    protected void mouse_release_event (QMouseEvent event) {
        if (!this.animation && QLine_f (this.press_point, event.position ()).length () < QGuiApplication.style_hints ().start_drag_distance ())
            /* emit */ clicked ();
    }


    /***********************************************************
    ***********************************************************/
    protected void paint_event (QPaintEvent event) {
        QPainter painter (this);

        if (this.animation) {
            int from = this.animation.start_value ().to_int ();
            int to = this.animation.end_value ().to_int ();
            qreal progress = this.animation.easing_curve ().value_for_progress (this.animation.current_time () / static_cast<qreal> (this.animation.duration ()));

            painter.save ();
            painter.opacity (1.0 - progress);
            painter.translate (progress * (this.reverse ? SLIDE_DISTANCE : -SLIDE_DISTANCE), 0);
            draw_slide (&painter, from);

            painter.restore ();
            painter.opacity (progress);
            painter.translate ( (1.0 - progress) * (this.reverse ? -SLIDE_DISTANCE : SLIDE_DISTANCE), 0);
            draw_slide (&painter, to);
        } else {
            draw_slide (&painter, this.current_index);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void timer_event (QTimerEvent event) {
        if (event.timer_id () == this.timer.timer_id ())
            on_signal_next_slide ();
    }


    /***********************************************************
    ***********************************************************/
    private void maybe_restart_timer () {
        if (!is_active ())
            return;

        on_signal_start_show ();
    }

} // class SlideShow

} // namespace Ui
} // namespace Occ
