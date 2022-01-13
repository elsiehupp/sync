/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>

namespace Occ {

class VfsXAttr : Vfs {

public:
    VfsXAttr (GLib.Object *parent = nullptr);
    ~VfsXAttr () override;

    Mode mode () const override;
    string fileSuffix () const override;

    void stop () override;
    void unregisterFolder () override;

    bool socketApiPinStateActionsShown () const override;
    bool isHydrating () const override;

    Result<void, string> updateMetadata (string &filePath, time_t modtime, int64 size, QByteArray &fileId) override;

    Result<void, string> createPlaceholder (SyncFileItem &item) override;
    Result<void, string> dehydratePlaceholder (SyncFileItem &item) override;
    Result<ConvertToPlaceholderResult, string> convertToPlaceholder (string &filename, SyncFileItem &item, string &replacesFile) override;

    bool needsMetadataUpdate (SyncFileItem &item) override;
    bool isDehydratedPlaceholder (string &filePath) override;
    bool statTypeVirtualFile (csync_file_stat_t *stat, void *statData) override;

    bool setPinState (string &folderPath, PinState state) override;
    Optional<PinState> pinState (string &folderPath) override;
    AvailabilityResult availability (string &folderPath) override;

public slots:
    void fileStatusChanged (string &systemFileName, SyncFileStatus fileStatus) override;

protected:
    void startImpl (VfsSetupParams &params) override;
};

class XattrVfsPluginFactory : GLib.Object, public DefaultPluginFactory<VfsXAttr> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

} // namespace Occ
