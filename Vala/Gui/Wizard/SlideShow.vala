/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QGuiApplication>
//  #include <QMouse_event>
//  #include <QPainter>
//  #include <QStyle>
//  #include <QStyle_hints>

const int HASQT5_11 (QT_VERSION >= QT_VERSION_CHECK (5,11,0))

//  #include <Gtk.Widget>
//  #include <QBasic_timer>
//  #include <QPointer>
//  #include <QVariant_animation>

namespace Occ {

/***********************************************************
@brief The Slide_show class
@ingroup gui
***********************************************************/
class Slide_show : Gtk.Widget {
    //  Q_PROPERTY (int interval READ interval WRITE set_interval)
    //  Q_PROPERTY (int current_slide READ current_slide WRITE set_current_slide NOTIFY current_slide_changed)

    /***********************************************************
    ***********************************************************/
    public Slide_show (Gtk.Widget* parent = null);

    /***********************************************************
    ***********************************************************/
    public void add_slide (QPixmap pixmap, string label);

    /***********************************************************
    ***********************************************************/
    public bool is_active ();

    /***********************************************************
    ***********************************************************/
    public int interval ();

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
    public void set_current_slide (int i

    /***********************************************************
    ***********************************************************/
    public QSize size_hint () override;

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_stop_show ();

    /***********************************************************
    ***********************************************************/
    public void on_next_slide ();


    public void on_prev_slide ();


    public void on_reset ();

signals:
    void clicked ();
    void current_slide_changed (int index);


    protected void mouse_press_event (QMouse_event event) override;
    protected void mouse_release_event (QMouse_event event) override;
    protected void paint_event (QPaint_event event) override;
    protected void timer_event (QTimerEvent event) override;


    /***********************************************************
    ***********************************************************/
    private void maybe_restart_timer ();

    /***********************************************************
    ***********************************************************/
    private 
    private bool this.reverse = false;
    private int this.interval = 3500;
    private int this.current_index = 0;
    private QPoint this.press_point;
    private QBasic_timer this.timer;
    private string[] this.labels;
    private GLib.Vector<QPixmap> this.pixmaps;
    private QPointer<QVariant_animation> this.animation = null;
}

const int Spacing = 6;
const int Slide_duration = 1000;
const int Slide_distance = 400;

Slide_show.Slide_show (Gtk.Widget parent) : Gtk.Widget (parent) {
    set_size_policy (QSize_policy.Minimum, QSize_policy.Minimum);
}

void Slide_show.add_slide (QPixmap pixmap, string label) {
    this.labels += label;
    this.pixmaps += pixmap;
    update_geometry ();
}

bool Slide_show.is_active () {
    return this.timer.is_active ();
}

int Slide_show.interval () {
    return this.interval;
}

void Slide_show.set_interval (int interval) {
    if (this.interval == interval)
        return;

    this.interval = interval;
    maybe_restart_timer ();
}

int Slide_show.current_slide () {
    return this.current_index;
}

void Slide_show.set_current_slide (int index) {
    if (this.current_index == index)
        return;

    if (!this.animation) {
        this.animation = new QVariant_animation (this);
        this.animation.set_duration (Slide_duration);
        this.animation.set_easing_curve (QEasing_curve.Out_cubic);
        this.animation.set_start_value (static_cast<qreal> (this.current_index));
        connect (this.animation.data (), SIGNAL (value_changed (GLib.Variant)), this, SLOT (update ()));
    }
    this.animation.set_end_value (static_cast<qreal> (index));
    this.animation.on_start (QAbstractAnimation.DeleteWhenStopped);

    this.reverse = index < this.current_index;
    this.current_index = index;
    maybe_restart_timer ();
    update ();
    /* emit */ current_slide_changed (index);
}

QSize Slide_show.size_hint () {
    QFontMetrics fm = font_metrics ();
    QSize label_size (0, fm.height ());
    for (string label : this.labels) {
#if (HASQT5_11)
        label_size.set_width (std.max (fm.horizontal_advance (label), label_size.width ()));
#else
        label_size.set_width (std.max (fm.width (label), label_size.width ()));
//  #endif
    }
    QSize pixmap_size;
    for (QPixmap pixmap : this.pixmaps) {
        pixmap_size.set_width (std.max (pixmap.width (), pixmap_size.width ()));
        pixmap_size.set_height (std.max (pixmap.height (), pixmap_size.height ()));
    }
    return {
        std.max (label_size.width (), pixmap_size.width ()),
        label_size.height () + Spacing + pixmap_size.height ()
    };
}

void Slide_show.on_start_show (int interval) {
    if (interval > 0)
        this.interval = interval;
    this.timer.on_start (this.interval, this);
}

void Slide_show.on_stop_show () {
    this.timer.stop ();
}

void Slide_show.on_next_slide () {
    set_current_slide ( (this.current_index + 1) % this.labels.count ());
    this.reverse = false;
}

void Slide_show.on_prev_slide () {
    set_current_slide ( (this.current_index > 0 ? this.current_index : this.labels.count ()) - 1);
    this.reverse = true;
}

void Slide_show.on_reset () {
    on_stop_show ();
    this.pixmaps.clear ();
    this.labels.clear ();
    update_geometry ();
    update ();
}

void Slide_show.mouse_press_event (QMouse_event event) {
    this.press_point = event.position ();
}

void Slide_show.mouse_release_event (QMouse_event event) {
    if (!this.animation && QLine_f (this.press_point, event.position ()).length () < QGuiApplication.style_hints ().start_drag_distance ())
        /* emit */ clicked ();
}

void Slide_show.paint_event (QPaint_event *) {
    QPainter painter (this);

    if (this.animation) {
        int from = this.animation.start_value ().to_int ();
        int to = this.animation.end_value ().to_int ();
        qreal progress = this.animation.easing_curve ().value_for_progress (this.animation.current_time () / static_cast<qreal> (this.animation.duration ()));

        painter.save ();
        painter.set_opacity (1.0 - progress);
        painter.translate (progress * (this.reverse ? Slide_distance : -Slide_distance), 0);
        draw_slide (&painter, from);

        painter.restore ();
        painter.set_opacity (progress);
        painter.translate ( (1.0 - progress) * (this.reverse ? -Slide_distance : Slide_distance), 0);
        draw_slide (&painter, to);
    } else {
        draw_slide (&painter, this.current_index);
    }
}

void Slide_show.timer_event (QTimerEvent event) {
    if (event.timer_id () == this.timer.timer_id ())
        on_next_slide ();
}

void Slide_show.maybe_restart_timer () {
    if (!is_active ())
        return;

    on_start_show ();
}

void Slide_show.draw_slide (QPainter painter, int index) {
    string label = this.labels.value (index);
    QRect label_rect = style ().item_text_rect (font_metrics (), rect (), Qt.Align_bottom | Qt.Align_hCenter, is_enabled (), label);
    style ().draw_item_text (painter, label_rect, Qt.AlignCenter, palette (), is_enabled (), label, QPalette.Window_text);

    QPixmap pixmap = this.pixmaps.value (index);
    QRect pixmap_rect = style ().item_pixmap_rect (QRect (0, 0, width (), label_rect.top () - Spacing), Qt.AlignCenter, pixmap);
    style ().draw_item_pixmap (painter, pixmap_rect, Qt.AlignCenter, pixmap);
}

} // namespace Occ
