/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QPaintDevice>
// #include <QTest>

class FakePaintDevice : QPaintDevice {
public:
    FakePaintDevice ();

    QPaintEngine *paintEngine () const override;

    void setHidpi (bool value);

protected:
    int metric (QPaintDevice.PaintDeviceMetric metric) const override;

private:
    bool _hidpi = false;
};
