

namespace Occ {
namespace Ui {

public class WebViewPageUrlRequestInterceptor { //: GLib.WebEngineUrlRequestInterceptor {

    /***********************************************************
    ***********************************************************/
    public WebViewPageUrlRequestInterceptor () {
        //  base ();
    }


    /***********************************************************
    ***********************************************************/
    public void intercept_request (GLib.WebEngineUrlRequestInfo info)  {
        //  info.http_header ("OCS-APIREQUEST", "true");
    }

} // class WebViewPageUrlRequestInterceptor

} // namespace Ui
} // namespace Occ
