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

    int interval {
        public get {
            return this.interval;
        }
        public set {
            if (this.interval == value) {
                return;
            }

            this.interval = value;
            maybe_restart_timer ();
        }
    }

    int current_slide {
        public get {
            return this.current_slide;
        }
        public set {
            if (this.current_slide == value)
                return;
    
            if (!this.animation) {
                this.animation = new QVariantAnimation (this);
                this.animation.duration (SLIDE_DURATION);
                this.animation.easing_curve (QEasing_curve.Out_cubic);
                this.animation.start_value (static_cast<qreal> (this.current_slide));
                connect (this.animation.data (), SIGNAL (value_changed (GLib.Variant)), this, SLOT (update ()));
            }
            this.animation.end_value (static_cast<qreal> (value));
            this.animation.on_signal_start (QAbstractAnimation.DeleteWhenStopped);
    
            this.reverse = value < this.current_slide;
            this.current_slide = value;
            maybe_restart_timer ();
            update ();
            /* emit */ signal_current_slide_changed (value);
        }
    }


    private QPoint press_point;
    private QBasic_timer timer;
    private string[] labels;
    private GLib.Vector<QPixmap> pixmaps;
    private QPointer<QVariantAnimation> animation = null;

    signal void signal_clicked ();
    signal void signal_current_slide_changed (int index);

    /***********************************************************
    ***********************************************************/
    public SlideShow (Gtk.Widget parent = null) {
        base (parent);
        this.current_slide = 0;
        this.interval = 3500;
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
    public QSize size_hint () {
        QFontMetrics font_metrics = font_metrics ();
        QSize label_size = new QSize (0, font_metrics.height ());
        foreach (string label in this.labels) {
            label_size.width (std.max (font_metrics.horizontal_advance (label), label_size.width ()));
        }
        QSize pixmap_size;
        foreach (QPixmap pixmap in this.pixmaps) {
            pixmap_size.width (std.max (pixmap.width (), pixmap_size.width ()));
            pixmap_size.height (std.max (pixmap.height (), pixmap_size.height ()));
        }
        return new QSize (
            std.max (label_size.width (), pixmap_size.width ()),
            label_size.height () + SPACING + pixmap_size.height ()
        );
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
        current_slide ( (this.current_slide + 1) % this.labels.count ());
        this.reverse = false;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_prev_slide () {
        current_slide ( (this.current_slide > 0 ? this.current_slide : this.labels.count ()) - 1);
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
            /* emit */ signal_clicked ();
    }


    /***********************************************************
    ***********************************************************/
    protected void paint_event (QPaintEvent event) {
        QPainter painter = new QPainter (this);

        if (this.animation) {
            int from = this.animation.start_value ().to_int ();
            int to = this.animation.end_value ().to_int ();
            qreal progress = this.animation.easing_curve ().value_for_progress (this.animation.current_time () / static_cast<qreal> (this.animation.duration ()));

            painter.save ();
            painter.opacity (1.0 - progress);
            painter.translate (progress * (this.reverse ? SLIDE_DISTANCE : -SLIDE_DISTANCE), 0);
            draw_slide (painter, from);

            painter.restore ();
            painter.opacity (progress);
            painter.translate ( (1.0 - progress) * (this.reverse ? -SLIDE_DISTANCE : SLIDE_DISTANCE), 0);
            draw_slide (painter, to);
        } else {
            draw_slide (painter, this.current_slide);
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
