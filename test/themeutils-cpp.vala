/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

FakePaintDevice.FakePaintDevice () = default;

QPaintEngine *FakePaintDevice.paintEngine () {
    return nullptr;
}

void FakePaintDevice.setHidpi (bool value) {
    _hidpi = value;
}

int FakePaintDevice.metric (QPaintDevice.PaintDeviceMetric metric) {
    switch (metric) {
    case QPaintDevice.PdmDevicePixelRatio:
        if (_hidpi) {
            return 2;
        }
        return 1;
    default:
        return QPaintDevice.metric (metric);
    }
}
