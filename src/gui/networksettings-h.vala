/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QWidget>

namespace Occ {

namespace Ui {
    class NetworkSettings;
}

/**
@brief The NetworkSettings class
@ingroup gui
*/
class NetworkSettings : QWidget {

public:
    NetworkSettings (QWidget *parent = nullptr);
    ~NetworkSettings () override;
    QSize sizeHint () const override;

private slots:
    void saveProxySettings ();
    void saveBWLimitSettings ();

    /// Red marking of host field if empty and enabled
    void checkEmptyProxyHost ();

    void checkAccountLocalhost ();

protected:
    void showEvent (QShowEvent *event) override;

private:
    void loadProxySettings ();
    void loadBWLimitSettings ();

    Ui.NetworkSettings *_ui;
};

} // namespace Occ