/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QMessageBox>
// #include <QNetworkProxy>
// #include <QDir>
// #include <QScopedValueRollback>
// #include <QMessageBox>

// #include <private/qzipwriter_p.h>

const int QTLEGACY (QT_VERSION < QT_VERSION_CHECK (5,9,0))

#if ! (QTLEGACY)
// #include <QOperatingSystemVersion>
#endif

// #include <Gtk.Widget>
// #include <QPointer>

namespace Occ {

namespace Ui {
    class GeneralSettings;
}

/***********************************************************
@brief The GeneralSettings class
@ingroup gui
***********************************************************/
class GeneralSettings : Gtk.Widget {

public:
    GeneralSettings (Gtk.Widget *parent = nullptr);
    ~GeneralSettings () override;
    QSize sizeHint () const override;

public slots:
    void slotStyleChanged ();

private slots:
    void saveMiscSettings ();
    void slotToggleLaunchOnStartup (bool);
    void slotToggleOptionalServerNotifications (bool);
    void slotShowInExplorerNavigationPane (bool);
    void slotIgnoreFilesEditor ();
    void slotCreateDebugArchive ();
    void loadMiscSettings ();
    void slotShowLegalNotice ();
#if defined (BUILD_UPDATER)
    void slotUpdateInfo ();
    void slotUpdateChannelChanged (string &channel);
    void slotUpdateCheckNow ();
    void slotToggleAutoUpdateCheck ();
#endif

private:
    void customizeStyle ();

    Ui.GeneralSettings *_ui;
    QPointer<IgnoreListEditor> _ignoreEditor;
    bool _currentlyLoading = false;
};

} // namespace Occ







namespace {
struct ZipEntry {
    string localFilename;
    string zipFilename;
};

ZipEntry fileInfoToZipEntry (QFileInfo &info) {
    return {
        info.absoluteFilePath (),
        info.fileName ()
    };
}

ZipEntry fileInfoToLogZipEntry (QFileInfo &info) {
    auto entry = fileInfoToZipEntry (info);
    entry.zipFilename.prepend (QStringLiteral ("logs/"));
    return entry;
}

ZipEntry syncFolderToZipEntry (Occ.Folder *f) {
    const auto journalPath = f.journalDb ().databaseFilePath ();
    const auto journalInfo = QFileInfo (journalPath);
    return fileInfoToZipEntry (journalInfo);
}

QVector<ZipEntry> createFileList () {
    auto list = QVector<ZipEntry> ();
    Occ.ConfigFile cfg;

    list.append (fileInfoToZipEntry (QFileInfo (cfg.configFile ())));

    const auto logger = Occ.Logger.instance ();

    if (!logger.logDir ().isEmpty ()) {
        list.append ({string (), QStringLiteral ("logs")});

        QDir dir (logger.logDir ());
        const auto infoList = dir.entryInfoList (QDir.Files);
        std.transform (std.cbegin (infoList), std.cend (infoList),
                       std.back_inserter (list),
                       fileInfoToLogZipEntry);
    } else if (!logger.logFile ().isEmpty ()) {
        list.append (fileInfoToZipEntry (QFileInfo (logger.logFile ())));
    }

    const auto folders = Occ.FolderMan.instance ().map ().values ();
    std.transform (std.cbegin (folders), std.cend (folders),
                   std.back_inserter (list),
                   syncFolderToZipEntry);

    return list;
}

void createDebugArchive (string &filename) {
    const auto entries = createFileList ();

    QZipWriter zip (filename);
    for (auto &entry : entries) {
        if (entry.localFilename.isEmpty ()) {
            zip.addDirectory (entry.zipFilename);
        } else {
            QFile file (entry.localFilename);
            if (!file.open (QFile.ReadOnly)) {
                continue;
            }
            zip.addFile (entry.zipFilename, &file);
        }
    }

    zip.addFile ("__nextcloud_client_parameters.txt", QCoreApplication.arguments ().join (' ').toUtf8 ());

    const auto buildInfo = string (Occ.Theme.instance ().about () + "\n\n" + Occ.Theme.instance ().aboutDetails ());
    zip.addFile ("__nextcloud_client_buildinfo.txt", buildInfo.toUtf8 ());
}
}

namespace Occ {

GeneralSettings.GeneralSettings (Gtk.Widget *parent)
    : Gtk.Widget (parent)
    , _ui (new Ui.GeneralSettings) {
    _ui.setupUi (this);

    connect (_ui.serverNotificationsCheckBox, &QAbstractButton.toggled,
        this, &GeneralSettings.slotToggleOptionalServerNotifications);
    _ui.serverNotificationsCheckBox.setToolTip (tr ("Server notifications that require attention."));

    connect (_ui.showInExplorerNavigationPaneCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.slotShowInExplorerNavigationPane);

    // Rename 'Explorer' appropriately on non-Windows

    if (Utility.hasSystemLaunchOnStartup (Theme.instance ().appName ())) {
        _ui.autostartCheckBox.setChecked (true);
        _ui.autostartCheckBox.setDisabled (true);
        _ui.autostartCheckBox.setToolTip (tr ("You cannot disable autostart because system-wide autostart is enabled."));
    } else {
        const bool hasAutoStart = Utility.hasLaunchOnStartup (Theme.instance ().appName ());
        // make sure the binary location is correctly set
        slotToggleLaunchOnStartup (hasAutoStart);
        _ui.autostartCheckBox.setChecked (hasAutoStart);
        connect (_ui.autostartCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.slotToggleLaunchOnStartup);
    }

    // setup about section
    string about = Theme.instance ().about ();
    _ui.aboutLabel.setTextInteractionFlags (Qt.TextSelectableByMouse | Qt.TextBrowserInteraction);
    _ui.aboutLabel.setText (about);
    _ui.aboutLabel.setOpenExternalLinks (true);

    // About legal notice
    connect (_ui.legalNoticeButton, &QPushButton.clicked, this, &GeneralSettings.slotShowLegalNotice);

    loadMiscSettings ();
    // updater info now set in : customizeStyle
    //slotUpdateInfo ();

    // misc
    connect (_ui.monoIconsCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.saveMiscSettings);
    connect (_ui.crashreporterCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.saveMiscSettings);
    connect (_ui.newFolderLimitCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.saveMiscSettings);
    connect (_ui.newFolderLimitSpinBox, static_cast<void (QSpinBox.*) (int)> (&QSpinBox.valueChanged), this, &GeneralSettings.saveMiscSettings);
    connect (_ui.newExternalStorage, &QAbstractButton.toggled, this, &GeneralSettings.saveMiscSettings);

#ifndef WITH_CRASHREPORTER
    _ui.crashreporterCheckBox.setVisible (false);
#endif

    // Hide on non-Windows
    _ui.showInExplorerNavigationPaneCheckBox.setVisible (false);

    /* Set the left contents margin of the layout to zero to make the checkboxes
    align properly vertically , fixes bug #3758
    ***********************************************************/
    int m0 = 0;
    int m1 = 0;
    int m2 = 0;
    int m3 = 0;
    _ui.horizontalLayout_3.getContentsMargins (&m0, &m1, &m2, &m3);
    _ui.horizontalLayout_3.setContentsMargins (0, m1, m2, m3);

    // OEM themes are not obliged to ship mono icons, so there
    // is no point in offering an option
    _ui.monoIconsCheckBox.setVisible (Theme.instance ().monoIconsAvailable ());

    connect (_ui.ignoredFilesButton, &QAbstractButton.clicked, this, &GeneralSettings.slotIgnoreFilesEditor);
    connect (_ui.debugArchiveButton, &QAbstractButton.clicked, this, &GeneralSettings.slotCreateDebugArchive);

    // accountAdded means the wizard was finished and the wizard might change some options.
    connect (AccountManager.instance (), &AccountManager.accountAdded, this, &GeneralSettings.loadMiscSettings);

    customizeStyle ();
}

GeneralSettings.~GeneralSettings () {
    delete _ui;
}

QSize GeneralSettings.sizeHint () {
    return {
        OwncloudGui.settingsDialogSize ().width (),
        Gtk.Widget.sizeHint ().height ()
    };
}

void GeneralSettings.loadMiscSettings () {
    QScopedValueRollback<bool> scope (_currentlyLoading, true);
    ConfigFile cfgFile;
    _ui.monoIconsCheckBox.setChecked (cfgFile.monoIcons ());
    _ui.serverNotificationsCheckBox.setChecked (cfgFile.optionalServerNotifications ());
    _ui.showInExplorerNavigationPaneCheckBox.setChecked (cfgFile.showInExplorerNavigationPane ());
    _ui.crashreporterCheckBox.setChecked (cfgFile.crashReporter ());
    auto newFolderLimit = cfgFile.newBigFolderSizeLimit ();
    _ui.newFolderLimitCheckBox.setChecked (newFolderLimit.first);
    _ui.newFolderLimitSpinBox.setValue (newFolderLimit.second);
    _ui.newExternalStorage.setChecked (cfgFile.confirmExternalStorage ());
    _ui.monoIconsCheckBox.setChecked (cfgFile.monoIcons ());
}

#if defined (BUILD_UPDATER)
void GeneralSettings.slotUpdateInfo () {
    if (ConfigFile ().skipUpdateCheck () || !Updater.instance ()) {
        // updater disabled on compile
        _ui.updatesGroupBox.setVisible (false);
        return;
    }

    // Note : the sparkle-updater is not an OCUpdater
    auto *ocupdater = qobject_cast<OCUpdater> (Updater.instance ());
    if (ocupdater) {
        connect (ocupdater, &OCUpdater.downloadStateChanged, this, &GeneralSettings.slotUpdateInfo, Qt.UniqueConnection);
        connect (_ui.restartButton, &QAbstractButton.clicked, ocupdater, &OCUpdater.slotStartInstaller, Qt.UniqueConnection);
        connect (_ui.restartButton, &QAbstractButton.clicked, qApp, &QApplication.quit, Qt.UniqueConnection);
        connect (_ui.updateButton, &QAbstractButton.clicked, this, &GeneralSettings.slotUpdateCheckNow, Qt.UniqueConnection);
        connect (_ui.autoCheckForUpdatesCheckBox, &QAbstractButton.toggled, this, &GeneralSettings.slotToggleAutoUpdateCheck);

        string status = ocupdater.statusString (OCUpdater.UpdateStatusStringFormat.Html);
        Theme.replaceLinkColorStringBackgroundAware (status);

        _ui.updateStateLabel.setOpenExternalLinks (false);
        connect (_ui.updateStateLabel, &QLabel.linkActivated, this, [] (string &link) {
            Utility.openBrowser (QUrl (link));
        });
        _ui.updateStateLabel.setText (status);

        _ui.restartButton.setVisible (ocupdater.downloadState () == OCUpdater.DownloadComplete);

        _ui.updateButton.setEnabled (ocupdater.downloadState () != OCUpdater.CheckingServer &&
                                      ocupdater.downloadState () != OCUpdater.Downloading &&
                                      ocupdater.downloadState () != OCUpdater.DownloadComplete);

        _ui.autoCheckForUpdatesCheckBox.setChecked (ConfigFile ().autoUpdateCheck ());
    }

    // Channel selection
    _ui.updateChannel.setCurrentIndex (ConfigFile ().updateChannel () == "beta" ? 1 : 0);
    connect (_ui.updateChannel, &QComboBox.currentTextChanged,
        this, &GeneralSettings.slotUpdateChannelChanged, Qt.UniqueConnection);
}

void GeneralSettings.slotUpdateChannelChanged (string &channel) {
    if (channel == ConfigFile ().updateChannel ())
        return;

    auto msgBox = new QMessageBox (
        QMessageBox.Warning,
        tr ("Change update channel?"),
        tr ("The update channel determines which client updates will be offered "
           "for installation. The \"stable\" channel contains only upgrades that "
           "are considered reliable, while the versions in the \"beta\" channel "
           "may contain newer features and bugfixes, but have not yet been tested "
           "thoroughly."
           "\n\n"
           "Note that this selects only what pool upgrades are taken from, and that "
           "there are no downgrades : So going back from the beta channel to "
           "the stable channel usually cannot be done immediately and means waiting "
           "for a stable version that is newer than the currently installed beta "
           "version."),
        QMessageBox.NoButton,
        this);
    auto acceptButton = msgBox.addButton (tr ("Change update channel"), QMessageBox.AcceptRole);
    msgBox.addButton (tr ("Cancel"), QMessageBox.RejectRole);
    connect (msgBox, &QMessageBox.finished, msgBox, [this, channel, msgBox, acceptButton] {
        msgBox.deleteLater ();
        if (msgBox.clickedButton () == acceptButton) {
            ConfigFile ().setUpdateChannel (channel);
            if (auto updater = qobject_cast<OCUpdater> (Updater.instance ())) {
                updater.setUpdateUrl (Updater.updateUrl ());
                updater.checkForUpdate ();
            }
        } else {
            _ui.updateChannel.setCurrentText (ConfigFile ().updateChannel ());
        }
    });
    msgBox.open ();
}

void GeneralSettings.slotUpdateCheckNow () {
    auto *updater = qobject_cast<OCUpdater> (Updater.instance ());
    if (ConfigFile ().skipUpdateCheck ()) {
        updater = nullptr; // don't show update info if updates are disabled
    }

    if (updater) {
        _ui.updateButton.setEnabled (false);

        updater.checkForUpdate ();
    }
}

void GeneralSettings.slotToggleAutoUpdateCheck () {
    ConfigFile cfgFile;
    bool isChecked = _ui.autoCheckForUpdatesCheckBox.isChecked ();
    cfgFile.setAutoUpdateCheck (isChecked, string ());
}
#endif // defined (BUILD_UPDATER)

void GeneralSettings.saveMiscSettings () {
    if (_currentlyLoading)
        return;
    ConfigFile cfgFile;
    bool isChecked = _ui.monoIconsCheckBox.isChecked ();
    cfgFile.setMonoIcons (isChecked);
    Theme.instance ().setSystrayUseMonoIcons (isChecked);
    cfgFile.setCrashReporter (_ui.crashreporterCheckBox.isChecked ());

    cfgFile.setNewBigFolderSizeLimit (_ui.newFolderLimitCheckBox.isChecked (),
        _ui.newFolderLimitSpinBox.value ());
    cfgFile.setConfirmExternalStorage (_ui.newExternalStorage.isChecked ());
}

void GeneralSettings.slotToggleLaunchOnStartup (bool enable) {
    Theme *theme = Theme.instance ();
    Utility.setLaunchOnStartup (theme.appName (), theme.appNameGUI (), enable);
}

void GeneralSettings.slotToggleOptionalServerNotifications (bool enable) {
    ConfigFile cfgFile;
    cfgFile.setOptionalServerNotifications (enable);
}

void GeneralSettings.slotShowInExplorerNavigationPane (bool checked) {
    ConfigFile cfgFile;
    cfgFile.setShowInExplorerNavigationPane (checked);
    // Now update the registry with the change.
    FolderMan.instance ().navigationPaneHelper ().setShowInExplorerNavigationPane (checked);
}

void GeneralSettings.slotIgnoreFilesEditor () {
    if (_ignoreEditor.isNull ()) {
        ConfigFile cfgFile;
        _ignoreEditor = new IgnoreListEditor (this);
        _ignoreEditor.setAttribute (Qt.WA_DeleteOnClose, true);
        _ignoreEditor.open ();
    } else {
        OwncloudGui.raiseDialog (_ignoreEditor);
    }
}

void GeneralSettings.slotCreateDebugArchive () {
    const auto filename = QFileDialog.getSaveFileName (this, tr ("Create Debug Archive"), string (), tr ("Zip Archives") + " (*.zip)");
    if (filename.isEmpty ()) {
        return;
    }

    createDebugArchive (filename);
    QMessageBox.information (this, tr ("Debug Archive Created"), tr ("Debug archive is created at %1").arg (filename));
}

void GeneralSettings.slotShowLegalNotice () {
    auto notice = new LegalNotice ();
    notice.exec ();
    delete notice;
}

void GeneralSettings.slotStyleChanged () {
    customizeStyle ();
}

void GeneralSettings.customizeStyle () {
    // setup about section
    string about = Theme.instance ().about ();
    Theme.replaceLinkColorStringBackgroundAware (about);
    _ui.aboutLabel.setText (about);

#if defined (BUILD_UPDATER)
    // updater info
    slotUpdateInfo ();
#else
    _ui.updatesGroupBox.setVisible (false);
#endif
}

} // namespace Occ
