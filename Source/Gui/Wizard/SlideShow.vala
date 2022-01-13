/***********************************************************
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QGuiApplication>
// #include <QMouseEvent>
// #include <QPainter>
// #include <QStyle>
// #include <QStyleHints>

const int HASQT5_11 (QT_VERSION >= QT_VERSION_CHECK (5,11,0))

// #include <Gtk.Widget>
// #include <QBasicTimer>
// #include <QPointer>
// #include <QVariantAnimation>

namespace Occ {

/***********************************************************
@brief The SlideShow class
@ingroup gui
***********************************************************/
class SlideShow : Gtk.Widget {
    Q_PROPERTY (int interval READ interval WRITE setInterval)
    Q_PROPERTY (int currentSlide READ currentSlide WRITE setCurrentSlide NOTIFY currentSlideChanged)

public:
    SlideShow (Gtk.Widget* parent = nullptr);

    void addSlide (QPixmap &pixmap, string &label);

    bool isActive ();

    int interval ();
    void setInterval (int interval);

    int currentSlide ();
    void setCurrentSlide (int index);

    QSize sizeHint () const override;

public slots:
    void startShow (int interval = 0);
    void stopShow ();
    void nextSlide ();
    void prevSlide ();
    void reset ();

signals:
    void clicked ();
    void currentSlideChanged (int index);

protected:
    void mousePressEvent (QMouseEvent *event) override;
    void mouseReleaseEvent (QMouseEvent *event) override;
    void paintEvent (QPaintEvent *event) override;
    void timerEvent (QTimerEvent *event) override;

private:
    void maybeRestartTimer ();
    void drawSlide (QPainter *painter, int index);

    bool _reverse = false;
    int _interval = 3500;
    int _currentIndex = 0;
    QPoint _pressPoint;
    QBasicTimer _timer;
    QStringList _labels;
    QVector<QPixmap> _pixmaps;
    QPointer<QVariantAnimation> _animation = nullptr;
};

static const int Spacing = 6;
static const int SlideDuration = 1000;
static const int SlideDistance = 400;

SlideShow.SlideShow (Gtk.Widget *parent) : Gtk.Widget (parent) {
    setSizePolicy (QSizePolicy.Minimum, QSizePolicy.Minimum);
}

void SlideShow.addSlide (QPixmap &pixmap, string &label) {
    _labels += label;
    _pixmaps += pixmap;
    updateGeometry ();
}

bool SlideShow.isActive () {
    return _timer.isActive ();
}

int SlideShow.interval () {
    return _interval;
}

void SlideShow.setInterval (int interval) {
    if (_interval == interval)
        return;

    _interval = interval;
    maybeRestartTimer ();
}

int SlideShow.currentSlide () {
    return _currentIndex;
}

void SlideShow.setCurrentSlide (int index) {
    if (_currentIndex == index)
        return;

    if (!_animation) {
        _animation = new QVariantAnimation (this);
        _animation.setDuration (SlideDuration);
        _animation.setEasingCurve (QEasingCurve.OutCubic);
        _animation.setStartValue (static_cast<qreal> (_currentIndex));
        connect (_animation.data (), SIGNAL (valueChanged (QVariant)), this, SLOT (update ()));
    }
    _animation.setEndValue (static_cast<qreal> (index));
    _animation.start (QAbstractAnimation.DeleteWhenStopped);

    _reverse = index < _currentIndex;
    _currentIndex = index;
    maybeRestartTimer ();
    update ();
    emit currentSlideChanged (index);
}

QSize SlideShow.sizeHint () {
    QFontMetrics fm = fontMetrics ();
    QSize labelSize (0, fm.height ());
    for (string &label : _labels) {
#if (HASQT5_11)
        labelSize.setWidth (std.max (fm.horizontalAdvance (label), labelSize.width ()));
#else
        labelSize.setWidth (std.max (fm.width (label), labelSize.width ()));
#endif
    }
    QSize pixmapSize;
    for (QPixmap &pixmap : _pixmaps) {
        pixmapSize.setWidth (std.max (pixmap.width (), pixmapSize.width ()));
        pixmapSize.setHeight (std.max (pixmap.height (), pixmapSize.height ()));
    }
    return {
        std.max (labelSize.width (), pixmapSize.width ()),
        labelSize.height () + Spacing + pixmapSize.height ()
    };
}

void SlideShow.startShow (int interval) {
    if (interval > 0)
        _interval = interval;
    _timer.start (_interval, this);
}

void SlideShow.stopShow () {
    _timer.stop ();
}

void SlideShow.nextSlide () {
    setCurrentSlide ( (_currentIndex + 1) % _labels.count ());
    _reverse = false;
}

void SlideShow.prevSlide () {
    setCurrentSlide ( (_currentIndex > 0 ? _currentIndex : _labels.count ()) - 1);
    _reverse = true;
}

void SlideShow.reset () {
    stopShow ();
    _pixmaps.clear ();
    _labels.clear ();
    updateGeometry ();
    update ();
}

void SlideShow.mousePressEvent (QMouseEvent *event) {
    _pressPoint = event.pos ();
}

void SlideShow.mouseReleaseEvent (QMouseEvent *event) {
    if (!_animation && QLineF (_pressPoint, event.pos ()).length () < QGuiApplication.styleHints ().startDragDistance ())
        emit clicked ();
}

void SlideShow.paintEvent (QPaintEvent *) {
    QPainter painter (this);

    if (_animation) {
        int from = _animation.startValue ().toInt ();
        int to = _animation.endValue ().toInt ();
        qreal progress = _animation.easingCurve ().valueForProgress (_animation.currentTime () / static_cast<qreal> (_animation.duration ()));

        painter.save ();
        painter.setOpacity (1.0 - progress);
        painter.translate (progress * (_reverse ? SlideDistance : -SlideDistance), 0);
        drawSlide (&painter, from);

        painter.restore ();
        painter.setOpacity (progress);
        painter.translate ( (1.0 - progress) * (_reverse ? -SlideDistance : SlideDistance), 0);
        drawSlide (&painter, to);
    } else {
        drawSlide (&painter, _currentIndex);
    }
}

void SlideShow.timerEvent (QTimerEvent *event) {
    if (event.timerId () == _timer.timerId ())
        nextSlide ();
}

void SlideShow.maybeRestartTimer () {
    if (!isActive ())
        return;

    startShow ();
}

void SlideShow.drawSlide (QPainter *painter, int index) {
    string label = _labels.value (index);
    QRect labelRect = style ().itemTextRect (fontMetrics (), rect (), Qt.AlignBottom | Qt.AlignHCenter, isEnabled (), label);
    style ().drawItemText (painter, labelRect, Qt.AlignCenter, palette (), isEnabled (), label, QPalette.WindowText);

    QPixmap pixmap = _pixmaps.value (index);
    QRect pixmapRect = style ().itemPixmapRect (QRect (0, 0, width (), labelRect.top () - Spacing), Qt.AlignCenter, pixmap);
    style ().drawItemPixmap (painter, pixmapRect, Qt.AlignCenter, pixmap);
}

} // namespace Occ
