/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <string>
// #include <QVariant>
#ifndef TOKEN_AUTH_ONLY
// #include <QPixmap>
// #include <QIcon>
#endif
// #include <QCoreApplication>

namespace Occ {

/***********************************************************
@brief The NextcloudTheme class
@ingroup libsync
***********************************************************/
class NextcloudTheme : Theme {

    public NextcloudTheme ();

    public string wizard_url_hint () override;
};

NextcloudTheme.NextcloudTheme ()
    : Theme () {
}

string NextcloudTheme.wizard_url_hint () {
    return string ("https://try.nextcloud.com");
}

}
