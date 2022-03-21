namespace Occ {
namespace Testing {

/***********************************************************
@class FakePaintDevice

@author 2021 Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class FakePaintDevice : QPaintDevice {

    /***********************************************************
    ***********************************************************/
    private bool hidpi = false;

    /***********************************************************
    ***********************************************************/
    public FakePaintDevice () {
        base ();
    }


    /***********************************************************
    ***********************************************************/
    public QPaintEngine paint_engine () {
        return null;
    }


    /***********************************************************
    ***********************************************************/
    public void set_hidpi (bool value) {
        this.hidpi = value;
    }


    /***********************************************************
    ***********************************************************/
    protected int metric (QPaintDevice.PaintDeviceMetric metric) {
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

} // class FakePaintDevice

} // namespace Testing
} // namespace Occ
