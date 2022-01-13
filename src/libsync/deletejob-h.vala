/*
 * Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
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

namespace OCC {

/**
 * @brief The DeleteJob class
 * @ingroup libsync
 */
class DeleteJob : public AbstractNetworkJob {
public:
    explicit DeleteJob(AccountPtr account, QString &path, QObject *parent = nullptr);
    explicit DeleteJob(AccountPtr account, QUrl &url, QObject *parent = nullptr);

    void start() override;
    bool finished() override;

    QByteArray folderToken() const;
    void setFolderToken(QByteArray &folderToken);

signals:
    void finishedSignal();

private:
    QUrl _url; // Only used if the constructor taking a url is taken.
    QByteArray _folderToken;
};
}
