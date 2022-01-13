/*
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

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
