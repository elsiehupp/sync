/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDesktopServices>
// #include <QDir>
// #include <QFileDialog>
// #include <QFileInfo>
// #include <QFile_icon_provider>
// #include <QInputDialog>
// #include <QValidator>
// #include <QWizard_page>
// #include <QTree_widget>
// #include <QVBoxLayout>
// #include <QEvent>
// #include <QCheckBox>
// #include <QMessageBox>

// #include <cstdlib>

// #include <QWizard>
// #include <QTimer>

using Soup;

namespace Occ {

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
class FolderWizard : QWizard {

    /***********************************************************
    ***********************************************************/
    public enum {
        Page_Source,
        Page_Target,
        Page_Selective_sync
    };

    /***********************************************************
    ***********************************************************/
    public FolderWizard (AccountPointer account, Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 
    public bool event_filter (GLib.Object watched, QEvent event) override;
    public void resize_event (QResizeEvent event) override;


    /***********************************************************
    ***********************************************************/
    private Folder_wizard_local_path this.folder_wizard_source_page;
    private Folder_wizard_remote_path this.folder_wizard_target_page;
    private Folder_wizard_selective_sync this.folder_wizard_selective_sync_page;
}





    /***********************************************************
    Folder wizard itself
    ***********************************************************/

    FolderWizard.FolderWizard (AccountPointer account, Gtk.Widget parent)
        : QWizard (parent)
        , this.folder_wizard_source_page (new Folder_wizard_local_path (account))
        , this.folder_wizard_target_page (nullptr)
        , this.folder_wizard_selective_sync_page (new Folder_wizard_selective_sync (account)) {
        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        set_page (Page_Source, this.folder_wizard_source_page);
        this.folder_wizard_source_page.install_event_filter (this);
        if (!Theme.instance ().single_sync_folder ()) {
            this.folder_wizard_target_page = new Folder_wizard_remote_path (account);
            set_page (Page_Target, this.folder_wizard_target_page);
            this.folder_wizard_target_page.install_event_filter (this);
        }
        set_page (Page_Selective_sync, this.folder_wizard_selective_sync_page);

        set_window_title (_("Add Folder Sync Connection"));
        set_options (QWizard.Cancel_button_on_left);
        set_button_text (QWizard.Finish_button, _("Add Sync Connection"));
    }

    FolderWizard.~FolderWizard () = default;

    bool FolderWizard.event_filter (GLib.Object watched, QEvent event) {
        if (event.type () == QEvent.Layout_request) {
            // Workaround QTBUG-3396 :  forces QWizard_private.update_layout ()
            QTimer.single_shot (0, this, [this] {
                set_title_format (title_format ());
            });
        }
        return QWizard.event_filter (watched, event);
    }

    void FolderWizard.resize_event (QResizeEvent event) {
        QWizard.resize_event (event);

        // workaround for QTBUG-22819 : when the error label word wrap, the minimum height is not adjusted
        if (var page = current_page ()) {
            int hfw = page.height_for_width (page.width ());
            if (page.height () < hfw) {
                page.set_minimum_size (page.minimum_size_hint ().width (), hfw);
                set_title_format (title_format ()); // And another workaround for QTBUG-3396
            }
        }
    }

    } // end namespace
    