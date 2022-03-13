

namespace Occ {
namespace Ui {

public class WebViewPageUrlRequestInterceptor : QWebEngineUrlRequestInterceptor {

    /***********************************************************
    ***********************************************************/
    public WebViewPageUrlRequestInterceptor (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public void intercept_request (QWebEngineUrlRequestInfo info)  {
        info.http_header ("OCS-APIREQUEST", "true");
    }

} // class WebViewPageUrlRequestInterceptor

} // namespace Ui
} // namespace Occ
