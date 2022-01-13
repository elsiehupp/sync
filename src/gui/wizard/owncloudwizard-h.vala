/*
 * Copyright (C) by Klaas Freitag <freitag@owncloud.com>
 * Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>
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

// #include <QWizard>
// #include <QLoggingCategory>
// #include <QSslKey>
// #include <QSslCertificate>

namespace OCC {

Q_DECLARE_LOGGING_CATEGORY (lcWizard)

class WelcomePage;
class OwncloudSetupPage;
class OwncloudHttpCredsPage;
class OwncloudOAuthCredsPage;
class OwncloudAdvancedSetupPage;
class OwncloudWizardResultPage;
class AbstractCredentials;
class AbstractCredentialsWizardPage;
class WebViewPage;
class Flow2AuthCredsPage;

/**
 * @brief The OwncloudWizard class
 * @ingroup gui
 */
class OwncloudWizard : public QWizard {
public:
    enum LogType {
        LogPlain,
        LogParagraph
    };

    OwncloudWizard (QWidget *parent = nullptr);

    void setAccount (AccountPtr account);
    AccountPtr account () const;
    void setOCUrl (QString &);
    bool registration ();
    void setRegistration (bool registration);

    void setupCustomMedia (QVariant, QLabel *);
    QString ocUrl () const;
    QString localFolder () const;
    QStringList selectiveSyncBlacklist () const;
    bool useVirtualFileSync () const;
    bool isConfirmBigFolderChecked () const;

    void displayError (QString &, bool retryHTTPonly);
    AbstractCredentials *getCredentials () const;

    void bringToTop ();
    void centerWindow ();

    /**
     * Shows a dialog explaining the virtual files mode and warning about it
     * being experimental. Calles the callback with true if enabling was
     * chosen.
     */
    static void askExperimentalVirtualFilesFeature (QWidget *receiver, std.function<void (bool enable)> &callback);

    // FIXME: Can those be local variables?
    // Set from the OwncloudSetupPage, later used from OwncloudHttpCredsPage
    QByteArray _clientCertBundle; // raw, potentially encrypted pkcs12 bundle provided by the user
    QByteArray _clientCertPassword; // password for the pkcs12
    QSslKey _clientSslKey; // key extracted from pkcs12
    QSslCertificate _clientSslCertificate; // cert extracted from pkcs12
    QList<QSslCertificate> _clientSslCaCertificates;

public slots:
    void setAuthType (DetermineAuthTypeJob.AuthType type);
    void setRemoteFolder (QString &);
    void appendToConfigurationLog (QString &msg, LogType type = LogParagraph);
    void slotCurrentPageChanged (int);
    void successfulStep ();

signals:
    void clearPendingRequests ();
    void determineAuthType (QString &);
    void connectToOCUrl (QString &);
    void createLocalAndRemoteFolders (QString &, QString &);
    // make sure to connect to this, rather than finished (int)!!
    void basicSetupFinished (int);
    void skipFolderConfiguration ();
    void needCertificate ();
    void styleChanged ();
    void onActivate ();

protected:
    void changeEvent (QEvent *) override;

private:
    void customizeStyle ();
    void adjustWizardSize ();
    int calculateLongestSideOfWizardPages (QList<QSize> &pageSizes) const;
    QList<QSize> calculateWizardPageSizes () const;

    AccountPtr _account;
    WelcomePage *_welcomePage;
    OwncloudSetupPage *_setupPage;
    OwncloudHttpCredsPage *_httpCredsPage;
    OwncloudOAuthCredsPage *_browserCredsPage;
    Flow2AuthCredsPage *_flow2CredsPage;
    OwncloudAdvancedSetupPage *_advancedSetupPage;
    OwncloudWizardResultPage *_resultPage;
    AbstractCredentialsWizardPage *_credentialsPage = nullptr;
    WebViewPage *_webViewPage = nullptr;

    QStringList _setupLog;

    bool _registration = false;

    friend class OwncloudSetupWizard;
};

} // namespace OCC

#endif
