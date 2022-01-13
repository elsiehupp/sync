/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <GLib.Object>
// #include <QScopedPointer>

namespace Occ {

class VfsCfApi : Vfs {

public:
    VfsCfApi (GLib.Object *parent = nullptr);
    ~VfsCfApi ();

    Mode mode () const override;
    string fileSuffix () const override;

    void stop () override;
    void unregisterFolder () override;

    bool socketApiPinStateActionsShown () const override;
    bool isHydrating () const override;

    Result<void, string> updateMetadata (string &filePath, time_t modtime, int64 size, QByteArray &fileId) override;

    Result<void, string> createPlaceholder (SyncFileItem &item) override;
    Result<void, string> dehydratePlaceholder (SyncFileItem &item) override;
    Result<Vfs.ConvertToPlaceholderResult, string> convertToPlaceholder (string &filename, SyncFileItem &item, string &replacesFile) override;

    bool needsMetadataUpdate (SyncFileItem &) override;
    bool isDehydratedPlaceholder (string &filePath) override;
    bool statTypeVirtualFile (csync_file_stat_t *stat, void *statData) override;

    bool setPinState (string &folderPath, PinState state) override;
    Optional<PinState> pinState (string &folderPath) override;
    AvailabilityResult availability (string &folderPath) override;

    void cancelHydration (string &requestId, string &path);

    int finalizeHydrationJob (string &requestId);

public slots:
    void requestHydration (string &requestId, string &path);
    void fileStatusChanged (string &systemFileName, SyncFileStatus fileStatus) override;

signals:
    void hydrationRequestReady (string &requestId);
    void hydrationRequestFailed (string &requestId);
    void hydrationRequestFinished (string &requestId);

protected:
    void startImpl (VfsSetupParams &params) override;

private:
    void scheduleHydrationJob (string &requestId, string &folderPath, SyncJournalFileRecord &record);
    void onHydrationJobFinished (HydrationJob *job);
    HydrationJob *findHydrationJob (string &requestId) const;

    struct HasHydratedDehydrated {
        bool hasHydrated = false;
        bool hasDehydrated = false;
    };
    struct HydratationAndPinStates {
        Optional<PinState> pinState;
        HasHydratedDehydrated hydrationStatus;
    };
    HydratationAndPinStates computeRecursiveHydrationAndPinStates (string &path, Optional<PinState> &basePinState);

    QScopedPointer<VfsCfApiPrivate> d;
};

class CfApiVfsPluginFactory : GLib.Object, public DefaultPluginFactory<VfsCfApi> {
    Q_PLUGIN_METADATA (IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};

} // namespace Occ
