/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
//  #include <Gtk.Icon>
//  #include <Gtk.Application>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The NextcloudTheme class
@ingroup libsync
***********************************************************/
public class NextcloudTheme : Theme {

    /***********************************************************
    ***********************************************************/
    public new const string WIZARD_URL_HINT = "https://try.nextcloud.com";

    /***********************************************************
    ***********************************************************/
    public NextcloudTheme () {
        base ();
    }

} // class NextcloudTheme

} // namespace LibSync
} // namespace Occ
