/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QGuiApplication>
// #include <QMouse_event>
// #include <QPainter>
// #include <QStyle>
// #include <QStyle_hints>

const int HASQT5_11 (QT_VERSION >= QT_VERSION_CHECK (5,11,0))

// #include <Gtk.Widget>
// #include <QBasic_timer>
// #include <QPointer>
// #include <QVariant_animation>

namespace Occ {

/***********************************************************
@brief The Slide_show class
@ingroup gui
***********************************************************/
class Slide_show : Gtk.Widget {
    Q_PROPERTY (int interval READ interval WRITE set_interval)
    Q_PROPERTY (int current_slide READ current_slide WRITE set_current_slide NOTIFY current_slide_changed)

    public Slide_show (Gtk.Widget* parent = nullptr);

    public void add_slide (QPixmap &pixmap, string label);

    public bool is_active ();

    public int interval ();


    public void set_interval (int interval);

    public int current_slide ();


    public void set_current_slide (int index);

    public QSize size_hint () override;


    public void on_start_show (int interval = 0);


    public void on_stop_show ();


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


    private void maybe_restart_timer ();
    private void draw_slide (QPainter painter, int index);

    private bool _reverse = false;
    private int _interval = 3500;
    private int _current_index = 0;
    private QPoint _press_point;
    private QBasic_timer _timer;
    private string[] _labels;
    private QVector<QPixmap> _pixmaps;
    private QPointer<QVariant_animation> _animation = nullptr;
};

static const int Spacing = 6;
static const int Slide_duration = 1000;
static const int Slide_distance = 400;

Slide_show.Slide_show (Gtk.Widget parent) : Gtk.Widget (parent) {
    set_size_policy (QSize_policy.Minimum, QSize_policy.Minimum);
}

void Slide_show.add_slide (QPixmap &pixmap, string label) {
    _labels += label;
    _pixmaps += pixmap;
    update_geometry ();
}

bool Slide_show.is_active () {
    return _timer.is_active ();
}

int Slide_show.interval () {
    return _interval;
}

void Slide_show.set_interval (int interval) {
    if (_interval == interval)
        return;

    _interval = interval;
    maybe_restart_timer ();
}

int Slide_show.current_slide () {
    return _current_index;
}

void Slide_show.set_current_slide (int index) {
    if (_current_index == index)
        return;

    if (!_animation) {
        _animation = new QVariant_animation (this);
        _animation.set_duration (Slide_duration);
        _animation.set_easing_curve (QEasing_curve.Out_cubic);
        _animation.set_start_value (static_cast<qreal> (_current_index));
        connect (_animation.data (), SIGNAL (value_changed (QVariant)), this, SLOT (update ()));
    }
    _animation.set_end_value (static_cast<qreal> (index));
    _animation.on_start (QAbstractAnimation.DeleteWhenStopped);

    _reverse = index < _current_index;
    _current_index = index;
    maybe_restart_timer ();
    update ();
    emit current_slide_changed (index);
}

QSize Slide_show.size_hint () {
    QFontMetrics fm = font_metrics ();
    QSize label_size (0, fm.height ());
    for (string label : _labels) {
#if (HASQT5_11)
        label_size.set_width (std.max (fm.horizontal_advance (label), label_size.width ()));
#else
        label_size.set_width (std.max (fm.width (label), label_size.width ()));
#endif
    }
    QSize pixmap_size;
    for (QPixmap &pixmap : _pixmaps) {
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
        _interval = interval;
    _timer.on_start (_interval, this);
}

void Slide_show.on_stop_show () {
    _timer.stop ();
}

void Slide_show.on_next_slide () {
    set_current_slide ( (_current_index + 1) % _labels.count ());
    _reverse = false;
}

void Slide_show.on_prev_slide () {
    set_current_slide ( (_current_index > 0 ? _current_index : _labels.count ()) - 1);
    _reverse = true;
}

void Slide_show.on_reset () {
    on_stop_show ();
    _pixmaps.clear ();
    _labels.clear ();
    update_geometry ();
    update ();
}

void Slide_show.mouse_press_event (QMouse_event event) {
    _press_point = event.pos ();
}

void Slide_show.mouse_release_event (QMouse_event event) {
    if (!_animation && QLine_f (_press_point, event.pos ()).length () < QGuiApplication.style_hints ().start_drag_distance ())
        emit clicked ();
}

void Slide_show.paint_event (QPaint_event *) {
    QPainter painter (this);

    if (_animation) {
        int from = _animation.start_value ().to_int ();
        int to = _animation.end_value ().to_int ();
        qreal progress = _animation.easing_curve ().value_for_progress (_animation.current_time () / static_cast<qreal> (_animation.duration ()));

        painter.save ();
        painter.set_opacity (1.0 - progress);
        painter.translate (progress * (_reverse ? Slide_distance : -Slide_distance), 0);
        draw_slide (&painter, from);

        painter.restore ();
        painter.set_opacity (progress);
        painter.translate ( (1.0 - progress) * (_reverse ? -Slide_distance : Slide_distance), 0);
        draw_slide (&painter, to);
    } else {
        draw_slide (&painter, _current_index);
    }
}

void Slide_show.timer_event (QTimerEvent event) {
    if (event.timer_id () == _timer.timer_id ())
        on_next_slide ();
}

void Slide_show.maybe_restart_timer () {
    if (!is_active ())
        return;

    on_start_show ();
}

void Slide_show.draw_slide (QPainter painter, int index) {
    string label = _labels.value (index);
    QRect label_rect = style ().item_text_rect (font_metrics (), rect (), Qt.Align_bottom | Qt.Align_hCenter, is_enabled (), label);
    style ().draw_item_text (painter, label_rect, Qt.AlignCenter, palette (), is_enabled (), label, QPalette.Window_text);

    QPixmap pixmap = _pixmaps.value (index);
    QRect pixmap_rect = style ().item_pixmap_rect (QRect (0, 0, width (), label_rect.top () - Spacing), Qt.AlignCenter, pixmap);
    style ().draw_item_pixmap (painter, pixmap_rect, Qt.AlignCenter, pixmap);
}

} // namespace Occ
