/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The NextcloudTheme class
@ingroup libsync
***********************************************************/
class NextcloudTheme : Theme {
public:
    NextcloudTheme ();

    string wizardUrlHint () const override;
};
}








/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <string>
// #include <QVariant>
#ifndef TOKEN_AUTH_ONLY
// #include <QPixmap>
// #include <QIcon>
#endif
// #include <QCoreApplication>

namespace Occ {

NextcloudTheme.NextcloudTheme ()
    : Theme () {
}

string NextcloudTheme.wizardUrlHint () {
    return string ("https://try.nextcloud.com");
}

}
