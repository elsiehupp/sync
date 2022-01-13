/*
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

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
class SyncLogDialog;

namespace Ui {
    class LegalNotice;
}

/**
@brief The LegalNotice class
@ingroup gui
*/
class LegalNotice : QDialog {

public:
    LegalNotice (QDialog *parent = nullptr);
    ~LegalNotice () override;

protected:
    void changeEvent (QEvent *) override;

private:
    void customizeStyle ();

    Ui.LegalNotice *_ui;
};

} // namespace Occ