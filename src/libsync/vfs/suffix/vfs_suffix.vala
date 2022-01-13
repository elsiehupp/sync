/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>

namespace Occ {

class VfsSuffix : Vfs {

public:
    VfsSuffix (GLib.Object *parent = nullptr);
    ~VfsSuffix () override;

    Mode mode () const override;
    string fileSuffix () const override;

    void stop () override;
    void unregisterFolder () override;

    bool socketApiPinStateActionsShown () const override { return true; }
    bool isHydrating () const override;

    Result<void, string> updateMetadata (string &filePath, time_t modtime, int64 size, QByteArray &fileId) override;

    Result<void, string> createPlaceholder (SyncFileItem &item) override;
    Result<void, string> dehydratePlaceholder (SyncFileItem &item) override;
    Result<Vfs.ConvertToPlaceholderResult, string> convertToPlaceholder (string &filename, SyncFileItem &item, string &) override;

    bool needsMetadataUpdate (SyncFileItem &) override { return false; }
    bool isDehydratedPlaceholder (string &filePath) override;
    bool statTypeVirtualFile (csync_file_stat_t *stat, void *stat_data) override;

    bool setPinState (string &folderPath, PinState state) override { return setPinStateInDb (folderPath, state); } {ptional<PinState> pinState (string &folderPath) override
    { return pinStateInDb (folderPath); }
    AvailabilityResult availability (string &folderPath) override;

public slots:
    void fileStatusChanged (string &, SyncFileStatus) override {}

protected:
    void startImpl (VfsSetupParams &params) override;
};

class SuffixVfsPluginFactory : GLib.Object, public DefaultPluginFactory<VfsSuffix> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

} // namespace Occ
