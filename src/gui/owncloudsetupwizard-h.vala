/*
 * Copyright (C) by Klaas Freitag <freitag@kde.org>
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

// #include <QObject>
// #include <QWidget>
// #include <QProcess>
// #include <QNetworkReply>
// #include <QPointer>

namespace OCC {

class AccountState;

class OwncloudWizard;

/**
 * @brief The OwncloudSetupWizard class
 * @ingroup gui
 */
class OwncloudSetupWizard : public QObject {
public:
    /** Run the wizard */
    static void runWizard (QObject *obj, char *amember, QWidget *parent = nullptr);
    static bool bringWizardToFrontIfVisible ();
signals:
    // overall dialog close signal.
    void ownCloudWizardDone (int);

private slots:
    void slotCheckServer (QString &);
    void slotSystemProxyLookupDone (QNetworkProxy &proxy);

    void slotFindServer ();
    void slotFindServerBehindRedirect ();
    void slotFoundServer (QUrl &, QJsonObject &);
    void slotNoServerFound (QNetworkReply *reply);
    void slotNoServerFoundTimeout (QUrl &url);

    void slotDetermineAuthType ();

    void slotConnectToOCUrl (QString &);
    void slotAuthError ();

    void slotCreateLocalAndRemoteFolders (QString &, QString &);
    void slotRemoteFolderExists (QNetworkReply *);
    void slotCreateRemoteFolderFinished (QNetworkReply *reply);
    void slotAssistantFinished (int);
    void slotSkipFolderConfiguration ();

private:
    explicit OwncloudSetupWizard (QObject *parent = nullptr);
    ~OwncloudSetupWizard () override;
    void startWizard ();
    void testOwnCloudConnect ();
    void createRemoteFolder ();
    void finalizeSetup (bool);
    bool ensureStartFromScratch (QString &localFolder);
    AccountState *applyAccountChanges ();
    bool checkDowngradeAdvised (QNetworkReply *reply);

    OwncloudWizard *_ocWizard;
    QString _initLocalFolder;
    QString _remoteFolder;
};
}

#endif // OWNCLOUDSETUPWIZARD_H
