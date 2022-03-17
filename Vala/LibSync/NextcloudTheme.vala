/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
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
