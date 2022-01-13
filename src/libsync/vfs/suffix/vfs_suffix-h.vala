/*
Copyright (C) by Christian Kamm <mail@ckamm.de>

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

class VfsSuffix : Vfs {

public:
    VfsSuffix (GLib.Object *parent = nullptr);
    ~VfsSuffix () override;

    Mode mode () const override;
    QString fileSuffix () const override;

    void stop () override;
    void unregisterFolder () override;

    bool socketApiPinStateActionsShown () const override { return true; }
    bool isHydrating () const override;

    Result<void, QString> updateMetadata (QString &filePath, time_t modtime, int64 size, QByteArray &fileId) override;

    Result<void, QString> createPlaceholder (SyncFileItem &item) override;
    Result<void, QString> dehydratePlaceholder (SyncFileItem &item) override;
    Result<Vfs.ConvertToPlaceholderResult, QString> convertToPlaceholder (QString &filename, SyncFileItem &item, QString &) override;

    bool needsMetadataUpdate (SyncFileItem &) override { return false; }
    bool isDehydratedPlaceholder (QString &filePath) override;
    bool statTypeVirtualFile (csync_file_stat_t *stat, void *stat_data) override;

    bool setPinState (QString &folderPath, PinState state) override { return setPinStateInDb (folderPath, state); } {ptional<PinState> pinState (QString &folderPath) override
    { return pinStateInDb (folderPath); }
    AvailabilityResult availability (QString &folderPath) override;

public slots:
    void fileStatusChanged (QString &, SyncFileStatus) override {}

protected:
    void startImpl (VfsSetupParams &params) override;
};

class SuffixVfsPluginFactory : GLib.Object, public DefaultPluginFactory<VfsSuffix> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

} // namespace Occ
