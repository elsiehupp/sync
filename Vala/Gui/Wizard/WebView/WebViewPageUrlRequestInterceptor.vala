

namespace Occ {

class Web_view_page_url_request_interceptor : QWeb_engine_url_request_interceptor {

    /***********************************************************
    ***********************************************************/
    public Web_view_page_url_request_interceptor (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void intercept_request (QWeb_engine_url_request_info info) override;
}

Web_view_page_url_request_interceptor.Web_view_page_url_request_interceptor (GLib.Object parent)
    : QWeb_engine_url_request_interceptor (parent) {

}

void Web_view_page_url_request_interceptor.intercept_request (QWeb_engine_url_request_info info) {
    info.set_http_header ("OCS-APIREQUEST", "true");
}
