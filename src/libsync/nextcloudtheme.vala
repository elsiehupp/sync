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