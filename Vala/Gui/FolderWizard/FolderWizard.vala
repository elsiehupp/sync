/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDesktopServices>
//  #include <QDir>
//  #include <QFileDialog>
//  #include <GLib.FileInfo>
//  #include <QFileIconProvider>
//  #include <QInputDialog>
//  #include <QValidator>
//  #include <QWizardPage>
//  #include <QTreeWidget>
//  #include <QVBoxLayout>
//  #include <QEvent>
//  #include <QCheckBox>
//  #include <QMessageBox>
//  #include <cstdlib>
//  #include <QWizard>
//  #include <QTimer>

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
public class FolderWizard : QWizard {

    /***********************************************************
    ***********************************************************/
    public enum Page {
        SOURCE,
        TARGET,
        SELECTIVE_SYNC
    }


    /***********************************************************
    ***********************************************************/
    private FolderWizardLocalPath folder_wizard_source_page;
    private FolderWizardRemotePath folder_wizard_target_page;
    private FolderWizardSelectiveSync folder_wizard_selective_sync_page;


    /***********************************************************
    Folder wizard itself
    ***********************************************************/
    public FolderWizard (unowned Account account, Gtk.Widget parent = null) {
        base (parent);
        this.folder_wizard_source_page = new FolderWizardLocalPath (account);
        this.folder_wizard_target_page = null;
        this.folder_wizard_selective_sync_page = new FolderWizardSelectiveSync (account);
        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        page (Page.SOURCE, this.folder_wizard_source_page);
        this.folder_wizard_source_page.install_event_filter (this);
        if (!Theme.instance ().single_sync_folder ()) {
            this.folder_wizard_target_page = new FolderWizardRemotePath (account);
            page (Page.TARGET, this.folder_wizard_target_page);
            this.folder_wizard_target_page.install_event_filter (this);
        }
        page (Page.SELECTIVE_SYNC, this.folder_wizard_selective_sync_page);

        window_title (_("Add Folder Sync Connection"));
        options (QWizard.Cancel_button_on_signal_left);
        button_text (QWizard.FinishButton, _("Add Sync Connection"));
    }


    /***********************************************************
    ***********************************************************/
    public override bool event_filter (GLib.Object watched, QEvent event) {
        if (event.type () == QEvent.Layout_request) {
            // Workaround QTBUG-3396: forces QWizard_private.update_layout ()
            QTimer.single_shot (
                0,
                this,
                this.on_event_filter_timer
            );
        }
        return QWizard.event_filter (watched, event);
    }


    /***********************************************************
    ***********************************************************/
    private void on_event_filter_timer () {
        title_format (title_format ());
    }


    /***********************************************************
    ***********************************************************/
    public override void resize_event (QResizeEvent event) {
        QWizard.resize_event (event);

        // workaround for QTBUG-22819: when the error label word wrap, the minimum height is not adjusted
        var page = current_page ();
        if (page) {
            int hfw = page.height_for_width (page.width ());
            if (page.height () < hfw) {
                page.minimum_size (page.minimum_size_hint ().width (), hfw);
                title_format (title_format ()); // And another workaround for QTBUG-3396
            }
        }
    }

} // class FolderWizard

} // namespace Ui
} // namespace Occ
