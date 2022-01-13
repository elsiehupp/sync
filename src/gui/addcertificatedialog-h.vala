/*
Copyright (C) 2015 by nocteau
Copyright (C) 2015 by Daniel Molkentin <danimo@owncloud.com>

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
// #include <QString>

namespace Occ {

namespace Ui {
    class AddCertificateDialog;
}

/**
@brief The AddCertificateDialog class
@ingroup gui
*/
class AddCertificateDialog : QDialog {

public:
    AddCertificateDialog (QWidget *parent = nullptr);
    ~AddCertificateDialog () override;
    QString getCertificatePath ();
    QString getCertificatePasswd ();
    void showErrorMessage (QString message);
    void reinit ();

private slots:
    void on_pushButtonBrowseCertificate_clicked ();

private:
    Ui.AddCertificateDialog *ui;
};

} //End namespace Occ
