/*
Copyright (C) 2015 by Christian Kamm <kamm@incasoftware.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

namespace Occ {

ProxyAuthDialog.ProxyAuthDialog (QWidget *parent)
    : QDialog (parent)
    , ui (new Ui.ProxyAuthDialog) {
    ui.setupUi (this);
}

ProxyAuthDialog.~ProxyAuthDialog () {
    delete ui;
}

void ProxyAuthDialog.setProxyAddress (QString &address) {
    ui.proxyAddress.setText (address);
}

QString ProxyAuthDialog.username () {
    return ui.usernameEdit.text ();
}

QString ProxyAuthDialog.password () {
    return ui.passwordEdit.text ();
}

void ProxyAuthDialog.reset () {
    ui.usernameEdit.setFocus ();
    ui.usernameEdit.clear ();
    ui.passwordEdit.clear ();
}

} // namespace Occ
