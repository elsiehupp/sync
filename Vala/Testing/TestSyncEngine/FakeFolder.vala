/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakeFolder { //: GLib.Object {

    //  /***********************************************************
    //  ***********************************************************/
    //  public class ErrorList {

    //      FakeQNAM soup_context;

    //      public void append (string path, int error = 500) {
    //          this.soup_context.error_paths ().insert (path, error);
    //      }

    //      public void clear () {
    //          this.soup_context.error_paths = "";
    //      }
    //  }

    //  GLib.TemporaryDir temporary_directory;
    //  public DiskFileModifier local_modifier;

    //  // FIXME: Clarify ownership, double delete
    //  FakeQNAM fake_access_manager;
    //  LibSync.Account account;
    //  Common.SyncJournalDb journal_database;
    //  public LibSync.SyncEngine sync_engine;


    //  /***********************************************************
    //  ***********************************************************/
    //  public FakeFolder (FileInfo template_file_info, Gpseq.Optional<FileInfo> local_file_info = new Gpseq.Optional<FileInfo> (), string remote_path = "") {
    //      this.local_modifier = this.temporary_directory.path;
    //      // Needs to be done once
    //      LibSync.SyncEngine.minimum_file_age_for_upload = std.chrono.milliseconds (0);
    //      LibSync.Logger.set_log_file ("-");
    //      LibSync.Logger.add_log_rule ({ "sync.httplogger=true" });

    //      GLib.Dir root_directory = new GLib.Dir (this.temporary_directory.path);
    //      GLib.debug ("FakeFolder operating on " + root_directory);
    //      if (local_file_info) {
    //          to_disk (root_directory, local_file_info);
    //      } else {
    //          to_disk (root_directory, template_file_info);
    //      }

    //      this.fake_access_manager = new FakeQNAM (template_file_info);
    //      this.account = LibSync.Account.create ();
    //      this.account.set_url (GLib.Uri ("http://admin:admin@localhost/owncloud"));
    //      this.account.set_credentials (new FakeCredentials (this.fake_access_manager));
    //      this.account.set_dav_display_name ("fakename");
    //      this.account.set_server_version ("10.0.0");

    //      this.journal_database = std.make_unique<Common.SyncJournalDb> (local_path + ".sync_test.db");
    //      this.sync_engine = std.make_unique<LibSync.SyncEngine> (this.account, local_path, remote_path, this.journal_database.get ());
    //      // Ignore temporary files from the download. (This is in the default exclude list, but we don't load it)
    //      this.sync_engine.excluded_files ().add_manual_exclude ("]*.~*");

    //      // handle signal_about_to_remove_all_files with a timeout in case our test does not handle it
    //      this.sync_engine.signal_about_to_remove_all_files.connect (
    //          this.on_signal_sync_engine_about_to_remove_all_files
    //      );

    //      // Ensure we have a valid VfsOff instance "running"
    //      switch_to_vfs (this.sync_engine.sync_options ().vfs);

    //      // A new folder will update the local file state database on first sync.
    //      // To have a state matching what users will encounter, we have to a sync
    //      // using an identical local/remote file tree first.
    //      //  ENFORCE (sync_once ());
    //  }


    //  delegate void Callback (bool value);


    //  void on_signal_sync_engine_about_to_remove_all_files (LibSync.SyncFileItem.Direction direction, Callback callback) {
    //      GLib.Timeout.add (
    //          1 * 1000,
    //          this.sync_engine.get ().on_timer_finished
    //      );
    //  }


    //  bool on_timer_finished (Callback callback) {
    //      callback (false);
    //      return false; // only run once
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void switch_to_vfs (Common.AbstractVfs vfs) {
    //      var opts = this.sync_engine.sync_options ();

    //      opts.vfs.stop ();
    //      disconnect (this.sync_engine.get (), null, opts.vfs, null);

    //      opts.vfs = vfs;
    //      this.sync_engine.set_sync_options (opts);

    //      Common.SetupParameters vfs_params;
    //      vfs_params.filesystem_path = local_path;
    //      vfs_params.remote_path = "/";
    //      vfs_params.account = this.account;
    //      vfs_params.journal = this.journal_database.get ();
    //      vfs_params.provider_name = "OC-TEST";
    //      vfs_params.provider_version = "0.1";
    //      this.sync_engine.destroyed.connect (
    //          vfs.on_signal_sync_engine_destroyed
    //      );
    //      vfs.on_signal_start (vfs_params);
    //  }


    //  private void on_signal_sync_engine_destroyed (Common.AbstractVfs vfs) {
    //      vfs.stop ();
    //      vfs.unregister_folder ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public LibSync.Account account {
    //      return this.account;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public Common.SyncJournalDb sync_journal () {
    //      return this.journal_database;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public AbstractFileModifier local_modifier {
    //      return this.local_modifier;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public FileInfo remote_modifier () {
    //      return this.fake_access_manager.current_remote_state ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public FileInfo current_local_state () {
    //      GLib.Dir root_directory = new GLib.Dir (this.temporary_directory.path);
    //      FileInfo root_template;
    //      from_disk (root_directory, root_template);
    //      root_template.fixup_parent_path_recursively ();
    //      return root_template;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public FileInfo current_remote_state () {
    //      return this.fake_access_manager.current_remote_state ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public FileInfo upload_state () {
    //      return this.fake_access_manager.upload_state ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public FileInfo database_state () {
    //      FileInfo result;
    //      this.journal_database.get_files_below_path (
    //          "",
    //          FakeFolder.database_record_filter
    //      );
    //      return result;
    //  }


    //  private void database_record_filter (Common.SyncJournalFileRecord record) {
    //      var components = new PathComponents (record.path);
    //      var parent_directory = find_or_create_directories (result, components.parent_directory_components ());
    //      var name = components.filename ();
    //      var item = parent_directory.children[name];
    //      item.name = name;
    //      item.parent_path = parent_directory.path;
    //      item.size = record.file_size;
    //      item.is_directory = record.type == ItemType.DIRECTORY;
    //      item.permissions = record.remote_permissions;
    //      item.etag = record.etag;
    //      item.last_modified = Utility.date_time_from_time_t (record.modtime);
    //      item.file_identifier = record.file_identifier;
    //      item.checksums = record.checksum_header;
    //      // item.content_char can't be set from the database
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public ErrorList server_error_paths () {
    //      return this.fake_access_manager;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void set_server_override (FakeQNAM.OverrideDelegate access_manager_override) {
    //      this.fake_access_manager.set_override(access_manager_override);
    //  }

    //  delegate Json.Object ReplyFunction (GLib.HashTable<string, string> map);

    //  /***********************************************************
    //  ***********************************************************/
    //  public Json.Object for_each_reply_part (
    //      GLib.OutputStream outgoing_data,
    //      string content_type,
    //      ReplyFunction reply_function) {
    //      return this.fake_access_manager.for_each_reply_part (outgoing_data, content_type, reply_function);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public string local_path {
    //      // LibSync.SyncEngine wants a trailing slash
    //      if (this.temporary_directory.path.has_suffix ("/"))
    //          return this.temporary_directory.path;
    //      return this.temporary_directory.path + "/";
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void schedule_sync () {
    //      // Have to be done async, else, an error before exec () does not terminate the event loop.
    //      GLib.Object.invoke_method (this.sync_engine.get (), "start_sync", GLib.QueuedConnection);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void exec_until_before_propagation () {
    //      GLib.SignalSpy spy = new GLib.SignalSpy (
    //          this.sync_engine.get (),
    //          this.sync_engine.signal_about_to_propagate
    //      );
    //      GLib.assert_true (spy.wait ());
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void exec_until_item_completed (string relative_path) {
    //      GLib.SignalSpy spy = new GLib.SignalSpy (
    //          this.sync_engine.get (),
    //          this.sync_engine.signal_item_completed
    //      );
    //      GLib.Timer t;
    //      t.on_signal_start ();
    //      while (t.elapsed () < 5000) {
    //          spy = "";
    //          GLib.assert_true (spy.wait ());
    //          foreach (GLib.List<GLib.Variant> args in spy) {
    //              var item = args[0].value<LibSync.SyncFileItem> ();
    //              if (item.destination () == relative_path)
    //                  return;
    //          }
    //      }
    //      GLib.assert_true (false);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool exec_until_finished () {
    //      GLib.SignalSpy spy = new GLib.SignalSpy (this.sync_engine.get (), SIGNAL (on_signal_finished (bool)));
    //      bool ok = spy.wait (3600000);
    //      GLib.assert_true (ok && "Sync timed out");
    //      return spy[0][0].to_bool ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool sync_once () {
    //      schedule_sync ();
    //      return exec_until_finished ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private static void to_disk (GLib.Dir directory, FileInfo template_file_info) {
    //      foreach (FileInfo child in template_file_info.children) {
    //          if (child.is_directory) {
    //              GLib.Dir sub_directory = new GLib.Dir (directory);
    //              directory.mkdir (child.name);
    //              sub_directory.cd (child.name);
    //              to_disk (sub_directory, child);
    //          } else {
    //              GLib.File file = new GLib.File (directory.file_path (child.name));
    //              file.open (GLib.File.WriteOnly);
    //              file.write ("".fill (child.content_char, child.size));
    //              file.close ();
    //              FileSystem.set_modification_time (file.filename (), Utility.date_time_to_time_t (child.last_modified));
    //          }
    //      }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private static void from_disk (GLib.Dir directory, FileInfo template_file_info) {
    //      foreach (GLib.FileInfo disk_child in directory.entry_info_list (GLib.Dir.AllEntries | GLib.Dir.NoDotAndDotDot)) {
    //          if (disk_child.is_directory ()) {
    //              GLib.Dir sub_directory = directory;
    //              sub_directory.cd (disk_child.filename ());
    //              FileInfo sub_file_info = template_file_info.children[disk_child.filename ()] = FileInfo ( disk_child.filename ());
    //              from_disk (sub_directory, sub_file_info);
    //          } else {
    //              GLib.File f = new GLib.File (disk_child.file_path);
    //              f.open (GLib.File.ReadOnly);
    //              var content = f.read (1);
    //              if (content.size () == 0) {
    //                  GLib.warning ("Empty file at: " + disk_child.file_path);
    //                  continue;
    //              }
    //              char content_char = content.at (0);
    //              template_file_info.children.insert (disk_child.filename (), new FileInfo (disk_child.filename (), disk_child.size (), content_char));
    //          }
    //      }
    //  }


    //  private static FileInfo find_or_create_directories (FileInfo base_file_info, PathComponents components) {
    //      if (components == "") {
    //          return base_file_info;
    //      }
    //      var child_name = components.path_root ();
    //      var it = base_file_info.children.find (child_name);
    //      if (it != base_file_info.children.end ()) {
    //          return find_or_create_directories (it, components.sub_components ());
    //      }
    //      var new_directory = base_file_info.children[child_name] = new FileInfo (child_name);
    //      new_directory.parent_path = base_file_info.path;
    //      return find_or_create_directories (new_directory, components.sub_components ());
    //  }

} // public class FakeFolder
} // namespace Testing
} // namespace Occ
