/*
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

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
    class ConflictDialog;
}

class ConflictDialog : QDialog {
public:
    ConflictDialog (QWidget *parent = nullptr);
    ~ConflictDialog () override;

    QString baseFilename ();
    QString localVersionFilename ();
    QString remoteVersionFilename ();

public slots:
    void setBaseFilename (QString &baseFilename);
    void setLocalVersionFilename (QString &localVersionFilename);
    void setRemoteVersionFilename (QString &remoteVersionFilename);

    void accept () override;

private:
    void updateWidgets ();
    void updateButtonStates ();

    QString _baseFilename;
    QScopedPointer<Ui.ConflictDialog> _ui;
    ConflictSolver *_solver;
};

} // namespace Occ
