/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Dir>
//  #include <GLib.List_widget>
//  #include <GLib.ListWidgetTtem>
//  #include <Gtk.MessageBox>
//  #include <GLib.InputDialog>
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The IgnoreListEditor class
@ingroup gui
***********************************************************/
public class IgnoreListEditor { //: Gtk.Dialog {

    private string read_only_tooltip;
    private IgnoreListEditor instance;

    /***********************************************************
    ***********************************************************/
    public IgnoreListEditor (Gtk.Widget parent = new Gtk.Widget ()) {
        //  base ();
        //  this.instance = new IgnoreListEditor ();
        //  window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);
        //  instance.up_ui (this);

        //  LibSync.ConfigFile config_file;
        //  //  FIXME This is not true. The entries are hardcoded below in setup_table_read_only_items
        //  read_only_tooltip = _("This entry is provided by the system at \"%1\" "
        //                      + "and cannot be modified in this view.")
        //                        .printf (GLib.Dir.to_native_separators (LibSync.ConfigFile.exclude_file (LibSync.ConfigFile.SYSTEM_SCOPE)));

        //  setup_table_read_only_items ();
        //  var user_config = LibSync.ConfigFile.exclude_file (LibSync.ConfigFile.Scope.USER_SCOPE);
        //  instance.ignore_table_widget.read_ignore_file (user_config);

        //  this.accepted.connect (
        //      this.on_dialog_accepted
        //  );
        //  instance.button_box.clicked.connect (
        //      this.on_signal_restore_defaults
        //  );

        //  instance.sync_hidden_files_check_box.checked (!FolderManager.instance.ignore_hidden_files);
    }


    /***********************************************************
    ***********************************************************/
    private void on_dialog_accepted () {
        //  instance.ignore_table_widget.on_signal_write_ignore_file (user_config);
        //  /* handle the hidden file checkbox */

        //  /* the ignore_hidden_files flag is a folder specific setting, but for now, it is
        // handled globally. Save it to every folder that is defined.
        // TODO this can now be fixed, simply attach this IgnoreListEditor to top-level account
        // settings
        //  */
        //  FolderManager.instance.ignore_hidden_files = this.ignore_hidden_files;
    }


    ~IgnoreListEditor () {
        //  //  delete instance;
    }


    /***********************************************************
    ***********************************************************/
    public bool ignore_hidden_files {
        public get {
            return !instance.sync_hidden_files_check_box.is_checked ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_restore_defaults (GLib.AbstractButton button) {
        //  if (instance.button_box.button_role (button) != GLib.DialogButtonBox.Reset_role) {
        //      return;
        //  }
        //  instance.ignore_table_widget.on_signal_remove_all_items ();

        //  LibSync.ConfigFile config_file;
        //  setup_table_read_only_items ();
        //  instance.ignore_table_widget.read_ignore_file (LibSync.ConfigFile.exclude_file (LibSync.ConfigFile.SYSTEM_SCOPE), false);
    }


    /***********************************************************
    ***********************************************************/
    private void setup_table_read_only_items () {
        //  instance.ignore_table_widget.add_pattern (".csync_journal.db*", /*deletable=*/false, /*read_only=*/true);
        //  instance.ignore_table_widget.add_pattern (".sync_*.db*", /*deletable=*/false, /*read_only=*/true);
        //  instance.ignore_table_widget.add_pattern (".sync_*.db*", /*deletable=*/false, /*read_only=*/true);
    }

} // class IgnoreListEditor

} // namespace Ui
} // namespace Occ
