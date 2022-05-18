/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.DesktopServices>
//  #include <GLib.Dir>
//  #include <GLib.FileDialog>
//  #include <GLib.FileInfo>
//  #include <GLib.FileIconProvider>
//  #include <GLib.InputDialog>
//  #include <GLib.Validator>
//  #include <GLib.WizardPage>
//  #include <GLib.TreeWidget>
//  #include <Gdk.Event>
//  #include <GLib.CheckBox>
//  #include <Gtk.MessageBox>
//  #include <cstdlib>
//  #include <GLib.Wizard>

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderWizard class
@ingroup gui
***********************************************************/
public class FolderWizard : GLib.Wizard {

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
    FolderConnection wizard itself
    ***********************************************************/
    public FolderWizard (unowned Account account, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.folder_wizard_source_page = new FolderWizardLocalPath (account);
        this.folder_wizard_target_page = null;
        this.folder_wizard_selective_sync_page = new FolderWizardSelectiveSync (account);
        window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);
        page (Page.SOURCE, this.folder_wizard_source_page);
        this.folder_wizard_source_page.install_event_filter (this);
        if (!Theme.single_sync_folder) {
            this.folder_wizard_target_page = new FolderWizardRemotePath (account);
            page (Page.TARGET, this.folder_wizard_target_page);
            this.folder_wizard_target_page.install_event_filter (this);
        }
        page (Page.SELECTIVE_SYNC, this.folder_wizard_selective_sync_page);

        window_title (_("Add FolderConnection Sync Connection"));
        options (GLib.Wizard.Cancel_button_on_signal_left);
        button_text (GLib.Wizard.FinishButton, _("Add Sync Connection"));
    }


    /***********************************************************
    ***********************************************************/
    public override bool event_filter (GLib.Object watched, Gdk.Event event) {
        if (event.type () == Gdk.Event.Layout_request) {
            // Workaround GLib.TBUG-3396: forces GLib.Wizard_private.update_layout ()
            GLib.Timeout.add (
                0,
                this.on_event_filter_timer
            );
        }
        return GLib.Wizard.event_filter (watched, event);
    }


    /***********************************************************
    ***********************************************************/
    private bool on_event_filter_timer () {
        title_format (title_format ());
        return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override void resize_event (GLib.ResizeEvent event) {
        GLib.Wizard.resize_event (event);

        // workaround for GLib.TBUG-22819: when the error label word wrap, the minimum height is not adjusted
        var page = current_page ();
        if (page) {
            int hfw = page.height_for_width (page.width ());
            if (page.height () < hfw) {
                page.minimum_size (page.minimum_size_hint ().width (), hfw);
                title_format (title_format ()); // And another workaround for GLib.TBUG-3396
            }
        }
    }

} // class FolderWizard

} // namespace Ui
} // namespace Occ
