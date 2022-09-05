namespace Occ {
namespace Testing {

/***********************************************************
@class FakePaintDevice

@author 2021 Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class FakePaintDevice : Gdk.Monitor {

    //  /***********************************************************
    //  ***********************************************************/
    //  private bool hidpi = false;

    //  /***********************************************************
    //  ***********************************************************/
    //  public FakePaintDevice () {
    //      base ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.PaintEngine paint_engine () {
    //      return null;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void set_hidpi (bool value) {
    //      this.hidpi = value;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected int metric (Gdk.Monitor.PaintDeviceMetric metric) {
    //      switch (metric) {
    //      case Gdk.Monitor.PdmDevicePixelRatio:
    //          if (this.hidpi) {
    //              return 2;
    //          }
    //          return 1;
    //      default:
    //          return Gdk.Monitor.metric (metric);
    //      }
    //  }

} // class FakePaintDevice

} // namespace Testing
} // namespace Occ
