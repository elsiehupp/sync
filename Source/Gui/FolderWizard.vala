/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDesktopServices>
// #include <QDir>
// #include <QFileDialog>
// #include <QFileInfo>
// #include <QFileIconProvider>
// #include <QInputDialog>
// #include <QUrl>
// #include <QValidator>
// #include <QWizardPage>
// #include <QTreeWidget>
// #include <QVBoxLayout>
// #include <QEvent>
// #include <QCheckBox>
// #include <QMessageBox>

// #include <cstdlib>

// #include <QWizard>
// #include <QNetworkReply>
// #include <QTimer>


namespace Occ {



/***********************************************************
@brief The FormatWarningsWizardPage class
@ingroup gui
***********************************************************/
class FormatWarningsWizardPage : QWizardPage {
protected:
    string formatWarnings (QStringList &warnings) const;
};

/***********************************************************
@brief Page to ask for the local source folder
@ingroup gui
***********************************************************/
class FolderWizardLocalPath : FormatWarningsWizardPage {
public:
    FolderWizardLocalPath (AccountPtr &account);
    ~FolderWizardLocalPath () override;

    bool isComplete () const override;
    void initializePage () override;
    void cleanupPage () override;

    void setFolderMap (Folder.Map &fm) { _folderMap = fm; }
protected slots:
    void slotChooseLocalFolder ();

private:
    Ui_FolderWizardSourcePage _ui;
    Folder.Map _folderMap;
    AccountPtr _account;
};

/***********************************************************
@brief page to ask for the target folder
@ingroup gui
***********************************************************/

class FolderWizardRemotePath : FormatWarningsWizardPage {
public:
    FolderWizardRemotePath (AccountPtr &account);
    ~FolderWizardRemotePath () override;

    bool isComplete () const override;

    void initializePage () override;
    void cleanupPage () override;

protected slots:

    void showWarn (string & = string ()) const;
    void slotAddRemoteFolder ();
    void slotCreateRemoteFolder (string &);
    void slotCreateRemoteFolderFinished ();
    void slotHandleMkdirNetworkError (QNetworkReply *);
    void slotHandleLsColNetworkError (QNetworkReply *);
    void slotUpdateDirectories (QStringList &);
    void slotGatherEncryptedPaths (string &, QMap<string, string> &);
    void slotRefreshFolders ();
    void slotItemExpanded (QTreeWidgetItem *);
    void slotCurrentItemChanged (QTreeWidgetItem *);
    void slotFolderEntryEdited (string &text);
    void slotLsColFolderEntry ();
    void slotTypedPathFound (QStringList &subpaths);

private:
    LsColJob *runLsColJob (string &path);
    void recursiveInsert (QTreeWidgetItem *parent, QStringList pathTrail, string path);
    bool selectByPath (string path);
    Ui_FolderWizardTargetPage _ui;
    bool _warnWasVisible;
    AccountPtr _account;
    QTimer _lscolTimer;
    QStringList _encryptedPaths;
};

/***********************************************************
@brief The FolderWizardSelectiveSync class
@ingroup gui
***********************************************************/
class FolderWizardSelectiveSync : QWizardPage {
public:
    FolderWizardSelectiveSync (AccountPtr &account);
    ~FolderWizardSelectiveSync () override;

    bool validatePage () override;

    void initializePage () override;
    void cleanupPage () override;

private slots:
    void virtualFilesCheckboxClicked ();

private:
    SelectiveSyncWidget *_selectiveSync;
    QCheckBox *_virtualFilesCheckBox = nullptr;
};

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
class FolderWizard : QWizard {
public:
    enum {
        Page_Source,
        Page_Target,
        Page_SelectiveSync
    };

    FolderWizard (AccountPtr account, Gtk.Widget *parent = nullptr);
    ~FolderWizard () override;

    bool eventFilter (GLib.Object *watched, QEvent *event) override;
    void resizeEvent (QResizeEvent *event) override;

private:
    FolderWizardLocalPath *_folderWizardSourcePage;
    FolderWizardRemotePath *_folderWizardTargetPage;
    FolderWizardSelectiveSync *_folderWizardSelectiveSyncPage;
};



    string FormatWarningsWizardPage.formatWarnings (QStringList &warnings) {
        string ret;
        if (warnings.count () == 1) {
            ret = tr ("<b>Warning:</b> %1").arg (warnings.first ());
        } else if (warnings.count () > 1) {
            ret = tr ("<b>Warning:</b>") + " <ul>";
            Q_FOREACH (string warning, warnings) {
                ret += string.fromLatin1 ("<li>%1</li>").arg (warning);
            }
            ret += "</ul>";
        }
    
        return ret;
    }
    
    FolderWizardLocalPath.FolderWizardLocalPath (AccountPtr &account)
        : FormatWarningsWizardPage ()
        , _account (account) {
        _ui.setupUi (this);
        registerField (QLatin1String ("sourceFolder*"), _ui.localFolderLineEdit);
        connect (_ui.localFolderChooseBtn, &QAbstractButton.clicked, this, &FolderWizardLocalPath.slotChooseLocalFolder);
        _ui.localFolderChooseBtn.setToolTip (tr ("Click to select a local folder to sync."));
    
        QUrl serverUrl = _account.url ();
        serverUrl.setUserName (_account.credentials ().user ());
        string defaultPath = QDir.homePath () + QLatin1Char ('/') + Theme.instance ().appName ();
        defaultPath = FolderMan.instance ().findGoodPathForNewSyncFolder (defaultPath, serverUrl);
        _ui.localFolderLineEdit.setText (QDir.toNativeSeparators (defaultPath));
        _ui.localFolderLineEdit.setToolTip (tr ("Enter the path to the local folder."));
    
        _ui.warnLabel.setTextFormat (Qt.RichText);
        _ui.warnLabel.hide ();
    }
    
    FolderWizardLocalPath.~FolderWizardLocalPath () = default;
    
    void FolderWizardLocalPath.initializePage () {
        _ui.warnLabel.hide ();
    }
    
    void FolderWizardLocalPath.cleanupPage () {
        _ui.warnLabel.hide ();
    }
    
    bool FolderWizardLocalPath.isComplete () {
        QUrl serverUrl = _account.url ();
        serverUrl.setUserName (_account.credentials ().user ());
    
        string errorStr = FolderMan.instance ().checkPathValidityForNewFolder (
            QDir.fromNativeSeparators (_ui.localFolderLineEdit.text ()), serverUrl);
    
        bool isOk = errorStr.isEmpty ();
        QStringList warnStrings;
        if (!isOk) {
            warnStrings << errorStr;
        }
    
        _ui.warnLabel.setWordWrap (true);
        if (isOk) {
            _ui.warnLabel.hide ();
            _ui.warnLabel.clear ();
        } else {
            _ui.warnLabel.show ();
            string warnings = formatWarnings (warnStrings);
            _ui.warnLabel.setText (warnings);
        }
        return isOk;
    }
    
    void FolderWizardLocalPath.slotChooseLocalFolder () {
        string sf = QStandardPaths.writableLocation (QStandardPaths.HomeLocation);
        QDir d (sf);
    
        // open the first entry of the home dir. Otherwise the dir picker comes
        // up with the closed home dir icon, stupid Qt default...
        QStringList dirs = d.entryList (QDir.Dirs | QDir.NoDotAndDotDot | QDir.NoSymLinks,
            QDir.DirsFirst | QDir.Name);
    
        if (dirs.count () > 0)
            sf += "/" + dirs.at (0); // Take the first dir in home dir.
    
        string dir = QFileDialog.getExistingDirectory (this,
            tr ("Select the source folder"),
            sf);
        if (!dir.isEmpty ()) {
            // set the last directory component name as alias
            _ui.localFolderLineEdit.setText (QDir.toNativeSeparators (dir));
        }
        emit completeChanged ();
    }
    
    // =================================================================================
    FolderWizardRemotePath.FolderWizardRemotePath (AccountPtr &account)
        : FormatWarningsWizardPage ()
        , _warnWasVisible (false)
        , _account (account)
     {
        _ui.setupUi (this);
        _ui.warnFrame.hide ();
    
        _ui.folderTreeWidget.setSortingEnabled (true);
        _ui.folderTreeWidget.sortByColumn (0, Qt.AscendingOrder);
    
        connect (_ui.addFolderButton, &QAbstractButton.clicked, this, &FolderWizardRemotePath.slotAddRemoteFolder);
        connect (_ui.refreshButton, &QAbstractButton.clicked, this, &FolderWizardRemotePath.slotRefreshFolders);
        connect (_ui.folderTreeWidget, &QTreeWidget.itemExpanded, this, &FolderWizardRemotePath.slotItemExpanded);
        connect (_ui.folderTreeWidget, &QTreeWidget.currentItemChanged, this, &FolderWizardRemotePath.slotCurrentItemChanged);
        connect (_ui.folderEntry, &QLineEdit.textEdited, this, &FolderWizardRemotePath.slotFolderEntryEdited);
    
        _lscolTimer.setInterval (500);
        _lscolTimer.setSingleShot (true);
        connect (&_lscolTimer, &QTimer.timeout, this, &FolderWizardRemotePath.slotLsColFolderEntry);
    
        _ui.folderTreeWidget.header ().setSectionResizeMode (0, QHeaderView.ResizeToContents);
        // Make sure that there will be a scrollbar when the contents is too wide
        _ui.folderTreeWidget.header ().setStretchLastSection (false);
    }
    
    void FolderWizardRemotePath.slotAddRemoteFolder () {
        QTreeWidgetItem *current = _ui.folderTreeWidget.currentItem ();
    
        string parent ('/');
        if (current) {
            parent = current.data (0, Qt.UserRole).toString ();
        }
    
        auto *dlg = new QInputDialog (this);
    
        dlg.setWindowTitle (tr ("Create Remote Folder"));
        dlg.setLabelText (tr ("Enter the name of the new folder to be created below \"%1\":")
                              .arg (parent));
        dlg.open (this, SLOT (slotCreateRemoteFolder (string)));
        dlg.setAttribute (Qt.WA_DeleteOnClose);
    }
    
    void FolderWizardRemotePath.slotCreateRemoteFolder (string &folder) {
        if (folder.isEmpty ())
            return;
    
        QTreeWidgetItem *current = _ui.folderTreeWidget.currentItem ();
        string fullPath;
        if (current) {
            fullPath = current.data (0, Qt.UserRole).toString ();
        }
        fullPath += "/" + folder;
    
        auto *job = new MkColJob (_account, fullPath, this);
        /* check the owncloud configuration file and query the ownCloud */
        connect (job, &MkColJob.finishedWithoutError,
            this, &FolderWizardRemotePath.slotCreateRemoteFolderFinished);
        connect (job, &AbstractNetworkJob.networkError, this, &FolderWizardRemotePath.slotHandleMkdirNetworkError);
        job.start ();
    }
    
    void FolderWizardRemotePath.slotCreateRemoteFolderFinished () {
        qCDebug (lcWizard) << "webdav mkdir request finished";
        showWarn (tr ("Folder was successfully created on %1.").arg (Theme.instance ().appNameGUI ()));
        slotRefreshFolders ();
        _ui.folderEntry.setText (static_cast<MkColJob> (sender ()).path ());
        slotLsColFolderEntry ();
    }
    
    void FolderWizardRemotePath.slotHandleMkdirNetworkError (QNetworkReply *reply) {
        qCWarning (lcWizard) << "webdav mkdir request failed:" << reply.error ();
        if (!_account.credentials ().stillValid (reply)) {
            showWarn (tr ("Authentication failed accessing %1").arg (Theme.instance ().appNameGUI ()));
        } else {
            showWarn (tr ("Failed to create the folder on %1. Please check manually.")
                         .arg (Theme.instance ().appNameGUI ()));
        }
    }
    
    void FolderWizardRemotePath.slotHandleLsColNetworkError (QNetworkReply *reply) {
        // Ignore 404s, otherwise users will get annoyed by error popups
        // when not typing fast enough. It's still clear that a given path
        // was not found, because the 'Next' button is disabled and no entry
        // is selected in the tree view.
        int httpCode = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
        if (httpCode == 404) {
            showWarn (string ()); // hides the warning pane
            return;
        }
        auto job = qobject_cast<LsColJob> (sender ());
        ASSERT (job);
        showWarn (tr ("Failed to list a folder. Error : %1")
                     .arg (job.errorStringParsingBody ()));
    }
    
    static QTreeWidgetItem *findFirstChild (QTreeWidgetItem *parent, string &text) {
        for (int i = 0; i < parent.childCount (); ++i) {
            QTreeWidgetItem *child = parent.child (i);
            if (child.text (0) == text) {
                return child;
            }
        }
        return nullptr;
    }
    
    void FolderWizardRemotePath.recursiveInsert (QTreeWidgetItem *parent, QStringList pathTrail, string path) {
        if (pathTrail.isEmpty ())
            return;
    
        const string parentPath = parent.data (0, Qt.UserRole).toString ();
        const string folderName = pathTrail.first ();
        string folderPath;
        if (parentPath == QLatin1String ("/")) {
            folderPath = folderName;
        } else {
            folderPath = parentPath + "/" + folderName;
        }
        QTreeWidgetItem *item = findFirstChild (parent, folderName);
        if (!item) {
            item = new QTreeWidgetItem (parent);
            QFileIconProvider prov;
            QIcon folderIcon = prov.icon (QFileIconProvider.Folder);
            item.setIcon (0, folderIcon);
            item.setText (0, folderName);
            item.setData (0, Qt.UserRole, folderPath);
            item.setToolTip (0, folderPath);
            item.setChildIndicatorPolicy (QTreeWidgetItem.ShowIndicator);
        }
    
        pathTrail.removeFirst ();
        recursiveInsert (item, pathTrail, path);
    }
    
    bool FolderWizardRemotePath.selectByPath (string path) {
        if (path.startsWith (QLatin1Char ('/'))) {
            path = path.mid (1);
        }
        if (path.endsWith (QLatin1Char ('/'))) {
            path.chop (1);
        }
    
        QTreeWidgetItem *it = _ui.folderTreeWidget.topLevelItem (0);
        if (!path.isEmpty ()) {
            const QStringList pathTrail = path.split (QLatin1Char ('/'));
            foreach (string &path, pathTrail) {
                if (!it) {
                    return false;
                }
                it = findFirstChild (it, path);
            }
        }
        if (!it) {
            return false;
        }
    
        _ui.folderTreeWidget.setCurrentItem (it);
        _ui.folderTreeWidget.scrollToItem (it);
        return true;
    }
    
    void FolderWizardRemotePath.slotUpdateDirectories (QStringList &list) {
        string webdavFolder = QUrl (_account.davUrl ()).path ();
    
        QTreeWidgetItem *root = _ui.folderTreeWidget.topLevelItem (0);
        if (!root) {
            root = new QTreeWidgetItem (_ui.folderTreeWidget);
            root.setText (0, Theme.instance ().appNameGUI ());
            root.setIcon (0, Theme.instance ().applicationIcon ());
            root.setToolTip (0, tr ("Choose this to sync the entire account"));
            root.setData (0, Qt.UserRole, "/");
        }
        QStringList sortedList = list;
        Utility.sortFilenames (sortedList);
        foreach (string path, sortedList) {
            path.remove (webdavFolder);
    
            // Don't allow to select subfolders of encrypted subfolders
            const auto isAnyAncestorEncrypted = std.any_of (std.cbegin (_encryptedPaths), std.cend (_encryptedPaths), [=] (string &encryptedPath) {
                return path.size () > encryptedPath.size () && path.startsWith (encryptedPath);
            });
            if (isAnyAncestorEncrypted) {
                continue;
            }
    
            QStringList paths = path.split ('/');
            if (paths.last ().isEmpty ())
                paths.removeLast ();
            recursiveInsert (root, paths, path);
        }
        root.setExpanded (true);
    }
    
    void FolderWizardRemotePath.slotGatherEncryptedPaths (string &path, QMap<string, string> &properties) {
        const auto it = properties.find ("is-encrypted");
        if (it == properties.cend () || *it != QStringLiteral ("1")) {
            return;
        }
    
        const auto webdavFolder = QUrl (_account.davUrl ()).path ();
        Q_ASSERT (path.startsWith (webdavFolder));
        _encryptedPaths << path.mid (webdavFolder.size ());
    }
    
    void FolderWizardRemotePath.slotRefreshFolders () {
        _encryptedPaths.clear ();
        runLsColJob ("/");
        _ui.folderTreeWidget.clear ();
        _ui.folderEntry.clear ();
    }
    
    void FolderWizardRemotePath.slotItemExpanded (QTreeWidgetItem *item) {
        string dir = item.data (0, Qt.UserRole).toString ();
        runLsColJob (dir);
    }
    
    void FolderWizardRemotePath.slotCurrentItemChanged (QTreeWidgetItem *item) {
        if (item) {
            string dir = item.data (0, Qt.UserRole).toString ();
    
            // We don't want to allow creating subfolders in encrypted folders outside of the sync logic
            const auto encrypted = _encryptedPaths.contains (dir);
            _ui.addFolderButton.setEnabled (!encrypted);
    
            if (!dir.startsWith (QLatin1Char ('/'))) {
                dir.prepend (QLatin1Char ('/'));
            }
            _ui.folderEntry.setText (dir);
        }
    
        emit completeChanged ();
    }
    
    void FolderWizardRemotePath.slotFolderEntryEdited (string &text) {
        if (selectByPath (text)) {
            _lscolTimer.stop ();
            return;
        }
    
        _ui.folderTreeWidget.setCurrentItem (nullptr);
        _lscolTimer.start (); // avoid sending a request on each keystroke
    }
    
    void FolderWizardRemotePath.slotLsColFolderEntry () {
        string path = _ui.folderEntry.text ();
        if (path.startsWith (QLatin1Char ('/')))
            path = path.mid (1);
    
        LsColJob *job = runLsColJob (path);
        // No error handling, no updating, we do this manually
        // because of extra logic in the typed-path case.
        disconnect (job, nullptr, this, nullptr);
        connect (job, &LsColJob.finishedWithError,
            this, &FolderWizardRemotePath.slotHandleLsColNetworkError);
        connect (job, &LsColJob.directoryListingSubfolders,
            this, &FolderWizardRemotePath.slotTypedPathFound);
    }
    
    void FolderWizardRemotePath.slotTypedPathFound (QStringList &subpaths) {
        slotUpdateDirectories (subpaths);
        selectByPath (_ui.folderEntry.text ());
    }
    
    LsColJob *FolderWizardRemotePath.runLsColJob (string &path) {
        auto *job = new LsColJob (_account, path, this);
        auto props = QList<QByteArray> () << "resourcetype";
        if (_account.capabilities ().clientSideEncryptionAvailable ()) {
            props << "http://nextcloud.org/ns:is-encrypted";
        }
        job.setProperties (props);
        connect (job, &LsColJob.directoryListingSubfolders,
            this, &FolderWizardRemotePath.slotUpdateDirectories);
        connect (job, &LsColJob.finishedWithError,
            this, &FolderWizardRemotePath.slotHandleLsColNetworkError);
        connect (job, &LsColJob.directoryListingIterated,
            this, &FolderWizardRemotePath.slotGatherEncryptedPaths);
        job.start ();
    
        return job;
    }
    
    FolderWizardRemotePath.~FolderWizardRemotePath () = default;
    
    bool FolderWizardRemotePath.isComplete () {
        if (!_ui.folderTreeWidget.currentItem ())
            return false;
    
        QStringList warnStrings;
        string dir = _ui.folderTreeWidget.currentItem ().data (0, Qt.UserRole).toString ();
        if (!dir.startsWith (QLatin1Char ('/'))) {
            dir.prepend (QLatin1Char ('/'));
        }
        wizard ().setProperty ("targetPath", dir);
    
        Folder.Map map = FolderMan.instance ().map ();
        Folder.Map.const_iterator i = map.constBegin ();
        for (i = map.constBegin (); i != map.constEnd (); i++) {
            auto *f = static_cast<Folder> (i.value ());
            if (f.accountState ().account () != _account) {
                continue;
            }
            string curDir = f.remotePathTrailingSlash ();
            if (QDir.cleanPath (dir) == QDir.cleanPath (curDir)) {
                warnStrings.append (tr ("This folder is already being synced."));
            } else if (dir.startsWith (curDir)) {
                warnStrings.append (tr ("You are already syncing <i>%1</i>, which is a parent folder of <i>%2</i>.").arg (Utility.escape (curDir), Utility.escape (dir)));
            } else if (curDir.startsWith (dir)) {
                warnStrings.append (tr ("You are already syncing <i>%1</i>, which is a subfolder of <i>%2</i>.").arg (Utility.escape (curDir), Utility.escape (dir)));
            }
        }
    
        showWarn (formatWarnings (warnStrings));
        return true;
    }
    
    void FolderWizardRemotePath.cleanupPage () {
        showWarn ();
    }
    
    void FolderWizardRemotePath.initializePage () {
        showWarn ();
        slotRefreshFolders ();
    }
    
    void FolderWizardRemotePath.showWarn (string &msg) {
        if (msg.isEmpty ()) {
            _ui.warnFrame.hide ();
    
        } else {
            _ui.warnFrame.show ();
            _ui.warnLabel.setText (msg);
        }
    }
    
    // ====================================================================================
    
    FolderWizardSelectiveSync.FolderWizardSelectiveSync (AccountPtr &account) {
        auto *layout = new QVBoxLayout (this);
        _selectiveSync = new SelectiveSyncWidget (account, this);
        layout.addWidget (_selectiveSync);
    
        if (Theme.instance ().showVirtualFilesOption () && bestAvailableVfsMode () != Vfs.Off) {
            _virtualFilesCheckBox = new QCheckBox (tr ("Use virtual files instead of downloading content immediately %1").arg (bestAvailableVfsMode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
            connect (_virtualFilesCheckBox, &QCheckBox.clicked, this, &FolderWizardSelectiveSync.virtualFilesCheckboxClicked);
            connect (_virtualFilesCheckBox, &QCheckBox.stateChanged, this, [this] (int state) {
                _selectiveSync.setEnabled (state == Qt.Unchecked);
            });
            _virtualFilesCheckBox.setChecked (bestAvailableVfsMode () == Vfs.WindowsCfApi);
            layout.addWidget (_virtualFilesCheckBox);
        }
    }
    
    FolderWizardSelectiveSync.~FolderWizardSelectiveSync () = default;
    
    void FolderWizardSelectiveSync.initializePage () {
        string targetPath = wizard ().property ("targetPath").toString ();
        if (targetPath.startsWith ('/')) {
            targetPath = targetPath.mid (1);
        }
        string alias = QFileInfo (targetPath).fileName ();
        if (alias.isEmpty ())
            alias = Theme.instance ().appName ();
        QStringList initialBlacklist;
        if (Theme.instance ().wizardSelectiveSyncDefaultNothing ()) {
            initialBlacklist = QStringList ("/");
        }
        _selectiveSync.setFolderInfo (targetPath, alias, initialBlacklist);
    
        if (_virtualFilesCheckBox) {
            // TODO : remove when UX decision is made
            if (Utility.isPathWindowsDrivePartitionRoot (wizard ().field (QStringLiteral ("sourceFolder")).toString ())) {
                _virtualFilesCheckBox.setChecked (false);
                _virtualFilesCheckBox.setEnabled (false);
                _virtualFilesCheckBox.setText (tr ("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            } else {
                _virtualFilesCheckBox.setChecked (bestAvailableVfsMode () == Vfs.WindowsCfApi);
                _virtualFilesCheckBox.setEnabled (true);
                _virtualFilesCheckBox.setText (tr ("Use virtual files instead of downloading content immediately %1").arg (bestAvailableVfsMode () == Vfs.WindowsCfApi ? string () : tr (" (experimental)")));
    
                if (Theme.instance ().enforceVirtualFilesSyncFolder ()) {
                    _virtualFilesCheckBox.setChecked (true);
                    _virtualFilesCheckBox.setDisabled (true);
                }
            }
            //
        }
    
        QWizardPage.initializePage ();
    }
    
    bool FolderWizardSelectiveSync.validatePage () {
        const bool useVirtualFiles = _virtualFilesCheckBox && _virtualFilesCheckBox.isChecked ();
        if (useVirtualFiles) {
            const auto availability = Vfs.checkAvailability (wizard ().field (QStringLiteral ("sourceFolder")).toString ());
            if (!availability) {
                auto msg = new QMessageBox (QMessageBox.Warning, tr ("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                msg.setAttribute (Qt.WA_DeleteOnClose);
                msg.open ();
                return false;
            }
        }
        wizard ().setProperty ("selectiveSyncBlackList", useVirtualFiles ? QVariant () : QVariant (_selectiveSync.createBlackList ()));
        wizard ().setProperty ("useVirtualFiles", QVariant (useVirtualFiles));
        return true;
    }
    
    void FolderWizardSelectiveSync.cleanupPage () {
        string targetPath = wizard ().property ("targetPath").toString ();
        string alias = QFileInfo (targetPath).fileName ();
        if (alias.isEmpty ())
            alias = Theme.instance ().appName ();
        _selectiveSync.setFolderInfo (targetPath, alias);
        QWizardPage.cleanupPage ();
    }
    
    void FolderWizardSelectiveSync.virtualFilesCheckboxClicked () {
        // The click has already had an effect on the box, so if it's
        // checked it was newly activated.
        if (_virtualFilesCheckBox.isChecked ()) {
            OwncloudWizard.askExperimentalVirtualFilesFeature (this, [this] (bool enable) {
                if (!enable)
                    _virtualFilesCheckBox.setChecked (false);
            });
        }
    }
    
    // ====================================================================================
    
    /***********************************************************
    Folder wizard itself
    ***********************************************************/
    
    FolderWizard.FolderWizard (AccountPtr account, Gtk.Widget *parent)
        : QWizard (parent)
        , _folderWizardSourcePage (new FolderWizardLocalPath (account))
        , _folderWizardTargetPage (nullptr)
        , _folderWizardSelectiveSyncPage (new FolderWizardSelectiveSync (account)) {
        setWindowFlags (windowFlags () & ~Qt.WindowContextHelpButtonHint);
        setPage (Page_Source, _folderWizardSourcePage);
        _folderWizardSourcePage.installEventFilter (this);
        if (!Theme.instance ().singleSyncFolder ()) {
            _folderWizardTargetPage = new FolderWizardRemotePath (account);
            setPage (Page_Target, _folderWizardTargetPage);
            _folderWizardTargetPage.installEventFilter (this);
        }
        setPage (Page_SelectiveSync, _folderWizardSelectiveSyncPage);
    
        setWindowTitle (tr ("Add Folder Sync Connection"));
        setOptions (QWizard.CancelButtonOnLeft);
        setButtonText (QWizard.FinishButton, tr ("Add Sync Connection"));
    }
    
    FolderWizard.~FolderWizard () = default;
    
    bool FolderWizard.eventFilter (GLib.Object *watched, QEvent *event) {
        if (event.type () == QEvent.LayoutRequest) {
            // Workaround QTBUG-3396 :  forces QWizardPrivate.updateLayout ()
            QTimer.singleShot (0, this, [this] { setTitleFormat (titleFormat ()); });
        }
        return QWizard.eventFilter (watched, event);
    }
    
    void FolderWizard.resizeEvent (QResizeEvent *event) {
        QWizard.resizeEvent (event);
    
        // workaround for QTBUG-22819 : when the error label word wrap, the minimum height is not adjusted
        if (auto page = currentPage ()) {
            int hfw = page.heightForWidth (page.width ());
            if (page.height () < hfw) {
                page.setMinimumSize (page.minimumSizeHint ().width (), hfw);
                setTitleFormat (titleFormat ()); // And another workaround for QTBUG-3396
            }
        }
    }
    
    } // end namespace
    