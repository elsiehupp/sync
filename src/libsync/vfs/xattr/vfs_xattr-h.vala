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
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>

namespace Occ {

class VfsXAttr : Vfs {

public:
    VfsXAttr (GLib.Object *parent = nullptr);
    ~VfsXAttr () override;

    Mode mode () const override;
    QString fileSuffix () const override;

    void stop () override;
    void unregisterFolder () override;

    bool socketApiPinStateActionsShown () const override;
    bool isHydrating () const override;

    Result<void, QString> updateMetadata (QString &filePath, time_t modtime, int64 size, QByteArray &fileId) override;

    Result<void, QString> createPlaceholder (SyncFileItem &item) override;
    Result<void, QString> dehydratePlaceholder (SyncFileItem &item) override;
    Result<ConvertToPlaceholderResult, QString> convertToPlaceholder (QString &filename, SyncFileItem &item, QString &replacesFile) override;

    bool needsMetadataUpdate (SyncFileItem &item) override;
    bool isDehydratedPlaceholder (QString &filePath) override;
    bool statTypeVirtualFile (csync_file_stat_t *stat, void *statData) override;

    bool setPinState (QString &folderPath, PinState state) override;
    Optional<PinState> pinState (QString &folderPath) override;
    AvailabilityResult availability (QString &folderPath) override;

public slots:
    void fileStatusChanged (QString &systemFileName, SyncFileStatus fileStatus) override;

protected:
    void startImpl (VfsSetupParams &params) override;
};

class XattrVfsPluginFactory : GLib.Object, public DefaultPluginFactory<VfsXAttr> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

} // namespace Occ
