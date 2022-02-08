

namespace Occ {
namespace Ui {

/***********************************************************
We need a separate class here, since we cannot simply return
the same WebEnginePage object. This leads to a strange
segfault somewhere deep inside of the QWebEngine code.
***********************************************************/
class ExternalWebEnginePage : QWebEnginePage {

    /***********************************************************
    ***********************************************************/
    public ExternalWebEnginePage (QWebEngineProfile profile, GLib.Object parent = new GLib.Object ()) {
        base (profile, parent);

    }

    /***********************************************************
    ***********************************************************/
    public bool accept_navigation_request (GLib.Uri url, QWebEnginePage.Navigation_type type, bool is_main_frame) {
        //  Q_UNUSED (type);
        //  Q_UNUSED (is_main_frame);
        Utility.open_browser (url);
        return false;
    }

} // class ExternalWebEnginePage

} // namespace Occ
} // namespace Ui
