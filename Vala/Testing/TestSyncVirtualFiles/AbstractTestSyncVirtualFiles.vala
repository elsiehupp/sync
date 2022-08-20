namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestSyncVirtualFiles

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class AbstractTestSyncVirtualFiles { //: GLib.Object {

//    protected const string DVSUFFIX = Common.Config.APPLICATION_DOTVIRTUALFILE_SUFFIX;

//    /***********************************************************
//    ***********************************************************/
//    protected static bool is_dehydrated (FakeFolder fake_folder, string path) {
//        string placeholder = path + DVSUFFIX;
//        return !fake_folder.current_local_state ().find (path)
//            && fake_folder.current_local_state ().find (placeholder);
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static bool has_dehydrated_database_entries (FakeFolder fake_folder, string path) {
//        Common.SyncJournalFileRecord normal;
//        Common.SyncJournalFileRecord suffix;
//        fake_folder.sync_journal ().get_file_record (path, normal);
//        fake_folder.sync_journal ().get_file_record (path + DVSUFFIX, suffix);
//        return !normal.is_valid && suffix.is_valid && suffix.type == ItemType.VIRTUAL_FILE;
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static void set_pin (FakeFolder fake_folder, string path, PinState state) {
//        fake_folder.sync_journal ().internal_pin_states.set_for_path (path, state);
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static bool item_instruction (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
//        var item = spy.find_item (path);
//        return item.instruction == instr;
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static Common.SyncJournalFileRecord database_record (FakeFolder folder, string path) {
//        Common.SyncJournalFileRecord record;
//        folder.sync_journal ().get_file_record (path, record);
//        return record;
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static void trigger_download (FakeFolder folder, string path) {
//        var journal = folder.sync_journal ();
//        Common.SyncJournalFileRecord record;
//        journal.get_file_record (path + DVSUFFIX, record);
//        if (!record.is_valid)
//            return;
//        record.type = ItemType.VIRTUAL_FILE_DOWNLOAD;
//        journal.set_file_record (record);
//        journal.schedule_path_for_remote_discovery (record.path);
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static void mark_for_dehydration (FakeFolder folder, string path) {
//        var journal = folder.sync_journal ();
//        Common.SyncJournalFileRecord record;
//        journal.get_file_record (path, record);
//        if (!record.is_valid)
//            return;
//        record.type = ItemType.VIRTUAL_FILE_DEHYDRATION;
//        journal.set_file_record (record);
//        journal.schedule_path_for_remote_discovery (record.path);
//    }


//    /***********************************************************
//    ***********************************************************/
//    protected static Common.AbstractVfs set_up_vfs (FakeFolder folder) {
//        var suffix_vfs = unowned<Common.AbstractVfs> (create_vfs_from_plugin (Common.AbstractVfs.WithSuffix).release ());
//        folder.switch_to_vfs (suffix_vfs);

//        // Using this directly doesn't recursively unpin everything and instead leaves
//        // the files in the hydration that that they on_signal_start with
//        folder.sync_journal ().internal_pin_states.set_for_path ("", PinState.UNSPECIFIED);

//        return suffix_vfs;
//    }

} // class AbstractTestSyncVirtualFiles

} // namespace Testing
} // namespace Occ
