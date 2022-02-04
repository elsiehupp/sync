/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #ifndef TOKEN_AUTH_ONLY
//  #include <QPixmap>
//  #include <QIcon>
//  #include
//  #include <QCoreApplication>

namespace Occ {

/***********************************************************
@brief The NextcloudTheme class
@ingroup libsync
***********************************************************/
class NextcloudTheme : Theme {

    /***********************************************************
    ***********************************************************/
    public const string WIZARD_URL_HINT = "https://try.nextcloud.com";

    /***********************************************************
    ***********************************************************/
    public NextcloudTheme () {
        base ();
    }

} // class NextcloudTheme

} // namespace Occ
