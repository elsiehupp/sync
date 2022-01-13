/*
 * Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */
// #pragma once

// #include <QObject>
// #include <QScopedPointer>

namespace OCC {
class HydrationJob;
class VfsCfApiPrivate;
class SyncJournalFileRecord;

class VfsCfApi : public Vfs {

public:
    explicit VfsCfApi(QObject *parent = nullptr);
    ~VfsCfApi();

    Mode mode() const override;
    QString fileSuffix() const override;

    void stop() override;
    void unregisterFolder() override;

    bool socketApiPinStateActionsShown() const override;
    bool isHydrating() const override;

    Result<void, QString> updateMetadata(QString &filePath, time_t modtime, qint64 size, QByteArray &fileId) override;

    Result<void, QString> createPlaceholder(SyncFileItem &item) override;
    Result<void, QString> dehydratePlaceholder(SyncFileItem &item) override;
    Result<Vfs::ConvertToPlaceholderResult, QString> convertToPlaceholder(QString &filename, SyncFileItem &item, QString &replacesFile) override;

    bool needsMetadataUpdate(SyncFileItem &) override;
    bool isDehydratedPlaceholder(QString &filePath) override;
    bool statTypeVirtualFile(csync_file_stat_t *stat, void *statData) override;

    bool setPinState(QString &folderPath, PinState state) override;
    Optional<PinState> pinState(QString &folderPath) override;
    AvailabilityResult availability(QString &folderPath) override;

    void cancelHydration(QString &requestId, QString &path);

    int finalizeHydrationJob(QString &requestId);

public slots:
    void requestHydration(QString &requestId, QString &path);
    void fileStatusChanged(QString &systemFileName, SyncFileStatus fileStatus) override;

signals:
    void hydrationRequestReady(QString &requestId);
    void hydrationRequestFailed(QString &requestId);
    void hydrationRequestFinished(QString &requestId);

protected:
    void startImpl(VfsSetupParams &params) override;

private:
    void scheduleHydrationJob(QString &requestId, QString &folderPath, SyncJournalFileRecord &record);
    void onHydrationJobFinished(HydrationJob *job);
    HydrationJob *findHydrationJob(QString &requestId) const;

    struct HasHydratedDehydrated {
        bool hasHydrated = false;
        bool hasDehydrated = false;
    };
    struct HydratationAndPinStates {
        Optional<PinState> pinState;
        HasHydratedDehydrated hydrationStatus;
    };
    HydratationAndPinStates computeRecursiveHydrationAndPinStates(QString &path, Optional<PinState> &basePinState);

    QScopedPointer<VfsCfApiPrivate> d;
};

class CfApiVfsPluginFactory : public QObject, public DefaultPluginFactory<VfsCfApi> {
    Q_PLUGIN_METADATA(IID "org.owncloud.PluginFactory" FILE "vfspluginmetadata.json")
    Q_INTERFACES(OCC::PluginFactory)
};

} // namespace OCC
