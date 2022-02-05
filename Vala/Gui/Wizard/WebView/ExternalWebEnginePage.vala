

namespace Occ {

// We need a separate class here, since we cannot simply return the same Web_engine_page object
// this leads to a strage segfault somewhere deep inside of the QWeb_engine code
class External_web_engine_page : QWeb_engine_page {

    /***********************************************************
    ***********************************************************/
    public External_web_engine_page (QWeb_engine_profile profile, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public bool accept_navigation_request (GLib.Uri url, QWeb_engine_page.Navigation_type type, bool is_main_frame) override;
}



External_web_engine_page.External_web_engine_page (QWeb_engine_profile profile, GLib.Object parent) : QWeb_engine_page (profile, parent) {

}

bool External_web_engine_page.accept_navigation_request (GLib.Uri url, QWeb_engine_page.Navigation_type type, bool is_main_frame) {
    //  Q_UNUSED (type);
    //  Q_UNUSED (is_main_frame);
    Utility.open_browser (url);
    return false;
}