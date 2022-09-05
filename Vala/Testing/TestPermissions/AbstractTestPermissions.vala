namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestPermissions

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class AbstractTestPermissions { //: GLib.Object {

    //  /***********************************************************
    //  Create some files
    //  ***********************************************************/
    //  protected static void insert_in (FakeFolder fake_folder, string directory, int cannot_be_modified_size) {
    //      fake_folder.remote_modifier ().insert (directory + "normal_file_PERM_WVND_.data", 100 );
    //      fake_folder.remote_modifier ().insert (directory + "cannot_be_removed_PERM_WVN_.data", 101 );
    //      fake_folder.remote_modifier ().insert (directory + "can_be_removed_PERM_D_.data", 102 );
    //      fake_folder.remote_modifier ().insert (directory + "cannot_be_modified_PERM_DVN_.data", cannot_be_modified_size, 'A');
    //      fake_folder.remote_modifier ().insert (directory + "can_be_modified_PERM_W_.data", can_be_modified_size);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static void remove_read_only (FakeFolder fake_folder, string file) {
    //      GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + file).permission (GLib.File.WriteOwner));
    //      GLib.File (fake_folder.local_path + file).set_permissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
    //      fake_folder.local_modifier.remove (file);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static void edit_read_only (FakeFolder fake_folder, string file)  {
    //      GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + file).permission (GLib.File.WriteOwner));
    //      GLib.File (fake_folder.local_path + file).set_permissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
    //      fake_folder.local_modifier.append_byte (file);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static void set_all_perm (FileInfo file_info, Common.RemotePermissions remote_permissions) {
    //      file_info.permissions = remote_permissions;
    //      foreach (var sub_file_info in file_info.children) {
    //          set_all_perm (sub_file_info, remote_permissions);
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static void apply_permissions_from_name (FileInfo info) {
    //      GLib.Regex regular_expression = new GLib.Regex ("this.PERM_ ([^this.]*)this.[^/]*$");
    //      var m = regular_expression.match (info.name);
    //      if (m.has_match ()) {
    //          info.permissions = Common.RemotePermissions.from_server_string (m.captured (1));
    //      }

    //      foreach (FileInfo sub in info.children) {
    //          apply_permissions_from_name (sub);
    //      }
    //  }


    //  /***********************************************************
    //  Check if the expected rows in the DB are non-empty. Note
    //  that in some cases they might be, then we cannot use this
    //  function.
    //     @see https://github.com/owncloud/client/issues/2038
    //  ***********************************************************/
    //  protected static static void assert_csync_journal_ok (Common.SyncJournalDb journal) {
    //      // The DB is openend in locked mode : close to allow us to access.
    //      journal.close ();

    //      Sqlite.Database database;
    //      GLib.assert_true (database.open_read_only (journal.database_file_path));
    //      SqlQuery sql_query = new SqlQuery ("SELECT count (*) from metadata where length (file_identifier) == 0", database);
    //      GLib.assert_true (sql_query.exec ());
    //      GLib.assert_true (sql_query.next ().has_data);
    //      GLib.assert_true (sql_query.int_value (0) == 0);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static LibSync.SyncFileItem find_discovery_item (GLib.List<LibSync.SyncFileItem> spy, string path) {
    //      foreach (var item in spy) {
    //          if (item.destination () == path) {
    //              return item;
    //          }
    //      }
    //      return new LibSync.SyncFileItem (new LibSync.SyncFileItem ());
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static bool item_instruction (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
    //      var item = spy.find_item (path);
    //      return item.instruction == instr;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected static bool discovery_instruction (GLib.List<LibSync.SyncFileItem> spy, string path, CSync.SyncInstructions instr) {
    //      var item = find_discovery_item (spy, path);
    //      return item.instruction == instr;
    //  }

} // class AbstractTestPermissions

} // namespace Testing
} // namespace Occ
