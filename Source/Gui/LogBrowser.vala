/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <cstdio>
// #include <iostream>

// #include <QDialogButtonBox>
// #include <QLayout>
// #include <QPushButton>
// #include <QLabel>
// #include <QDir>
// #include <QTextStream>
// #include <QMessageBox>
// #include <QCoreApplication>
// #include <QSettings>
// #include <QAction>
// #include <QDesktopServices>

// #include <QCheckBox>
// #include <QPlainTextEdit>
// #include <QTextStream>
// #include <QFile>
// #include <GLib.Object>
// #include <QList>
// #include <QDateTime>
// #include <Gtk.Dialog>
// #include <QLineEdit>
// #include <QPushButton>
// #include <QLabel>

namespace Occ {

/***********************************************************
@brief The LogBrowser class
@ingroup gui
***********************************************************/
class LogBrowser : Gtk.Dialog {
public:
    LogBrowser (Gtk.Widget *parent = nullptr);
    ~LogBrowser () override;

protected:
    void closeEvent (QCloseEvent *) override;

protected slots:
    void togglePermanentLogging (bool enabled);
};


    LogBrowser.LogBrowser (Gtk.Widget *parent)
        : Gtk.Dialog (parent) {
        setWindowFlags (windowFlags () & ~Qt.WindowContextHelpButtonHint);
        setObjectName ("LogBrowser"); // for save/restoreGeometry ()
        setWindowTitle (tr ("Log Output"));
        setMinimumWidth (600);
    
        auto mainLayout = new QVBoxLayout;
    
        auto label = new QLabel (
            tr ("The client can write debug logs to a temporary folder. "
               "These logs are very helpful for diagnosing problems.\n"
               "Since log files can get large, the client will start a new one for each sync "
               "run and compress older ones. It will also delete log files after a couple "
               "of hours to avoid consuming too much disk space.\n"
               "If enabled, logs will be written to %1")
            .arg (Logger.instance ().temporaryFolderLogDirPath ()));
        label.setWordWrap (true);
        label.setTextInteractionFlags (Qt.TextSelectableByMouse);
        label.setSizePolicy (QSizePolicy.Expanding, QSizePolicy.MinimumExpanding);
        mainLayout.addWidget (label);
    
        // button to permanently save logs
        auto enableLoggingButton = new QCheckBox;
        enableLoggingButton.setText (tr ("Enable logging to temporary folder"));
        enableLoggingButton.setChecked (ConfigFile ().automaticLogDir ());
        connect (enableLoggingButton, &QCheckBox.toggled, this, &LogBrowser.togglePermanentLogging);
        mainLayout.addWidget (enableLoggingButton);
    
        label = new QLabel (
            tr ("This setting persists across client restarts.\n"
               "Note that using any logging command line options will override this setting."));
        label.setWordWrap (true);
        label.setSizePolicy (QSizePolicy.Expanding, QSizePolicy.MinimumExpanding);
        mainLayout.addWidget (label);
    
        auto openFolderButton = new QPushButton;
        openFolderButton.setText (tr ("Open folder"));
        connect (openFolderButton, &QPushButton.clicked, this, [] () {
            string path = Logger.instance ().temporaryFolderLogDirPath ();
            QDir ().mkpath (path);
            QDesktopServices.openUrl (QUrl.fromLocalFile (path));
        });
        mainLayout.addWidget (openFolderButton);
    
        auto *btnbox = new QDialogButtonBox;
        QPushButton *closeBtn = btnbox.addButton (QDialogButtonBox.Close);
        connect (closeBtn, &QAbstractButton.clicked, this, &Gtk.Widget.close);
    
        mainLayout.addStretch ();
        mainLayout.addWidget (btnbox);
    
        setLayout (mainLayout);
    
        setModal (false);
    
        auto showLogWindow = new QAction (this);
        showLogWindow.setShortcut (QKeySequence ("F12"));
        connect (showLogWindow, &QAction.triggered, this, &Gtk.Widget.close);
        addAction (showLogWindow);
    
        ConfigFile cfg;
        cfg.restoreGeometry (this);
    }
    
    LogBrowser.~LogBrowser () = default;
    
    void LogBrowser.closeEvent (QCloseEvent *) {
        ConfigFile cfg;
        cfg.saveGeometry (this);
    }
    
    void LogBrowser.togglePermanentLogging (bool enabled) {
        ConfigFile ().setAutomaticLogDir (enabled);
    
        auto logger = Logger.instance ();
        if (enabled) {
            if (!logger.isLoggingToFile ()) {
                logger.setupTemporaryFolderLogDir ();
                logger.enterNextLogFile ();
            }
        } else {
            logger.disableTemporaryFolderLogDir ();
        }
    }
    
    } // namespace
    