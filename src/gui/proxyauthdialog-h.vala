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

// #include <QDialog>

namespace Occ {

namespace Ui {
    class ProxyAuthDialog;
}

/**
@brief Ask for username and password for a given proxy.

Used by ProxyAuthHandler.
*/
class ProxyAuthDialog : QDialog {

public:
    ProxyAuthDialog (QWidget *parent = nullptr);
    ~ProxyAuthDialog () override;

    void setProxyAddress (QString &address);

    QString username ();
    QString password ();

    /// Resets the dialog for new credential entry.
    void reset ();

private:
    Ui.ProxyAuthDialog *ui;
};

} // namespace Occ