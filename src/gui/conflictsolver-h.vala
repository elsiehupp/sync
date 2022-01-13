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

// #include <GLib.Object>


namespace Occ {

class ConflictSolver : GLib.Object {
    Q_PROPERTY (QString localVersionFilename READ localVersionFilename WRITE setLocalVersionFilename NOTIFY localVersionFilenameChanged)
    Q_PROPERTY (QString remoteVersionFilename READ remoteVersionFilename WRITE setRemoteVersionFilename NOTIFY remoteVersionFilenameChanged)
public:
    enum Solution {
        KeepLocalVersion,
        KeepRemoteVersion,
        KeepBothVersions
    };

    ConflictSolver (QWidget *parent = nullptr);

    QString localVersionFilename ();
    QString remoteVersionFilename ();

    bool exec (Solution solution);

public slots:
    void setLocalVersionFilename (QString &localVersionFilename);
    void setRemoteVersionFilename (QString &remoteVersionFilename);

signals:
    void localVersionFilenameChanged ();
    void remoteVersionFilenameChanged ();

private:
    bool deleteLocalVersion ();
    bool renameLocalVersion ();
    bool overwriteRemoteVersion ();

    QWidget *_parentWidget;
    QString _localVersionFilename;
    QString _remoteVersionFilename;
};

} // namespace Occ
