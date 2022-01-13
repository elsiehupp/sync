/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <Gtk.Dialog>

namespace Occ {


namespace Ui {
    class ConflictDialog;
}

class ConflictDialog : Gtk.Dialog {
public:
    ConflictDialog (Gtk.Widget *parent = nullptr);
    ~ConflictDialog () override;

    string baseFilename ();
    string localVersionFilename ();
    string remoteVersionFilename ();

public slots:
    void setBaseFilename (string &baseFilename);
    void setLocalVersionFilename (string &localVersionFilename);
    void setRemoteVersionFilename (string &remoteVersionFilename);

    void accept () override;

private:
    void updateWidgets ();
    void updateButtonStates ();

    string _baseFilename;
    QScopedPointer<Ui.ConflictDialog> _ui;
    ConflictSolver *_solver;
};

} // namespace Occ








/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QDateTime>
// #include <QDebug>
// #include <QDesktopServices>
// #include <QFileInfo>
// #include <QMimeDatabase>
// #include <QPushButton>
// #include <QUrl>

namespace {
    void forceHeaderFont (Gtk.Widget *widget) {
        auto font = widget.font ();
        font.setPointSizeF (font.pointSizeF () * 1.5);
        widget.setFont (font);
    }
    
    void setBoldFont (Gtk.Widget *widget, bool bold) {
        auto font = widget.font ();
        font.setBold (bold);
        widget.setFont (font);
    }
    }
    
    namespace Occ {
    
    ConflictDialog.ConflictDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.ConflictDialog)
        , _solver (new ConflictSolver (this)) {
        _ui.setupUi (this);
        forceHeaderFont (_ui.conflictMessage);
        _ui.buttonBox.button (QDialogButtonBox.Ok).setEnabled (false);
        _ui.buttonBox.button (QDialogButtonBox.Ok).setText (tr ("Keep selected version"));
    
        connect (_ui.localVersionRadio, &QCheckBox.toggled, this, &ConflictDialog.updateButtonStates);
        connect (_ui.localVersionButton, &QToolButton.clicked, this, [=] {
            QDesktopServices.openUrl (QUrl.fromLocalFile (_solver.localVersionFilename ()));
        });
    
        connect (_ui.remoteVersionRadio, &QCheckBox.toggled, this, &ConflictDialog.updateButtonStates);
        connect (_ui.remoteVersionButton, &QToolButton.clicked, this, [=] {
            QDesktopServices.openUrl (QUrl.fromLocalFile (_solver.remoteVersionFilename ()));
        });
    
        connect (_solver, &ConflictSolver.localVersionFilenameChanged, this, &ConflictDialog.updateWidgets);
        connect (_solver, &ConflictSolver.remoteVersionFilenameChanged, this, &ConflictDialog.updateWidgets);
    }
    
    string ConflictDialog.baseFilename () {
        return _baseFilename;
    }
    
    ConflictDialog.~ConflictDialog () = default;
    
    string ConflictDialog.localVersionFilename () {
        return _solver.localVersionFilename ();
    }
    
    string ConflictDialog.remoteVersionFilename () {
        return _solver.remoteVersionFilename ();
    }
    
    void ConflictDialog.setBaseFilename (string &baseFilename) {
        if (_baseFilename == baseFilename) {
            return;
        }
    
        _baseFilename = baseFilename;
        _ui.conflictMessage.setText (tr ("Conflicting versions of %1.").arg (_baseFilename));
    }
    
    void ConflictDialog.setLocalVersionFilename (string &localVersionFilename) {
        _solver.setLocalVersionFilename (localVersionFilename);
    }
    
    void ConflictDialog.setRemoteVersionFilename (string &remoteVersionFilename) {
        _solver.setRemoteVersionFilename (remoteVersionFilename);
    }
    
    void ConflictDialog.accept () {
        const auto isLocalPicked = _ui.localVersionRadio.isChecked ();
        const auto isRemotePicked = _ui.remoteVersionRadio.isChecked ();
    
        Q_ASSERT (isLocalPicked || isRemotePicked);
        if (!isLocalPicked && !isRemotePicked) {
            return;
        }
    
        const auto solution = isLocalPicked && isRemotePicked ? ConflictSolver.KeepBothVersions
                            : isLocalPicked ? ConflictSolver.KeepLocalVersion
                            : ConflictSolver.KeepRemoteVersion;
        if (_solver.exec (solution)) {
            Gtk.Dialog.accept ();
        }
    }
    
    void ConflictDialog.updateWidgets () {
        QMimeDatabase mimeDb;
    
        const auto updateGroup = [this, &mimeDb] (string &filename, QLabel *linkLabel, string &linkText, QLabel *mtimeLabel, QLabel *sizeLabel, QToolButton *button) {
            const auto fileUrl = QUrl.fromLocalFile (filename).toString ();
            linkLabel.setText (QStringLiteral ("<a href='%1'>%2</a>").arg (fileUrl).arg (linkText));
    
            const auto info = QFileInfo (filename);
            mtimeLabel.setText (info.lastModified ().toString ());
            sizeLabel.setText (locale ().formattedDataSize (info.size ()));
    
            const auto mime = mimeDb.mimeTypeForFile (filename);
            if (QIcon.hasThemeIcon (mime.iconName ())) {
                button.setIcon (QIcon.fromTheme (mime.iconName ()));
            } else {
                button.setIcon (QIcon (":/qt-project.org/styles/commonstyle/images/file-128.png"));
            }
        };
    
        const auto localVersion = _solver.localVersionFilename ();
        updateGroup (localVersion,
                    _ui.localVersionLink,
                    tr ("Open local version"),
                    _ui.localVersionMtime,
                    _ui.localVersionSize,
                    _ui.localVersionButton);
    
        const auto remoteVersion = _solver.remoteVersionFilename ();
        updateGroup (remoteVersion,
                    _ui.remoteVersionLink,
                    tr ("Open server version"),
                    _ui.remoteVersionMtime,
                    _ui.remoteVersionSize,
                    _ui.remoteVersionButton);
    
        const auto localMtime = QFileInfo (localVersion).lastModified ();
        const auto remoteMtime = QFileInfo (remoteVersion).lastModified ();
    
        setBoldFont (_ui.localVersionMtime, localMtime > remoteMtime);
        setBoldFont (_ui.remoteVersionMtime, remoteMtime > localMtime);
    }
    
    void ConflictDialog.updateButtonStates () {
        const auto isLocalPicked = _ui.localVersionRadio.isChecked ();
        const auto isRemotePicked = _ui.remoteVersionRadio.isChecked ();
        _ui.buttonBox.button (QDialogButtonBox.Ok).setEnabled (isLocalPicked || isRemotePicked);
    
        const auto text = isLocalPicked && isRemotePicked ? tr ("Keep both versions")
                        : isLocalPicked ? tr ("Keep local version")
                        : isRemotePicked ? tr ("Keep server version")
                        : tr ("Keep selected version");
        _ui.buttonBox.button (QDialogButtonBox.Ok).setText (text);
    }
    
    } // namespace Occ
    