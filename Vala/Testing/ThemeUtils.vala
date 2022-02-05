/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/


//  #include <QPaintDevice>
//  #include <QTest>

class FakePaintDevice : QPaintDevice {

    /***********************************************************
    ***********************************************************/
    public FakePaintDevice ();

    /***********************************************************
    ***********************************************************/
    public QPaintEngine paintEngine () override;

    /***********************************************************
    ***********************************************************/
    public void setHidpi (bool value);

    protected int metric (QPaintDevice.PaintDeviceMetric metric) override;

    /***********************************************************
    ***********************************************************/
    private bool this.hidpi = false;
}










/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

FakePaintDevice.FakePaintDevice () = default;

QPaintEngine *FakePaintDevice.paintEngine () {
    return null;
}

void FakePaintDevice.setHidpi (bool value) {
    this.hidpi = value;
}

int FakePaintDevice.metric (QPaintDevice.PaintDeviceMetric metric) {
    switch (metric) {
    case QPaintDevice.PdmDevicePixelRatio:
        if (this.hidpi) {
            return 2;
        }
        return 1;
    default:
        return QPaintDevice.metric (metric);
    }
}
