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
@brief The Nextcloud_theme class
@ingroup libsync
***********************************************************/
class Nextcloud_theme : Theme {
public:
    Nextcloud_theme ();

    string wizard_url_hint () const override;
};

Nextcloud_theme.Nextcloud_theme ()
    : Theme () {
}

string Nextcloud_theme.wizard_url_hint () {
    return string ("https://try.nextcloud.com");
}

}
