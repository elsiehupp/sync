namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestSyncXAttr

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestSyncXAttr { //: GLib.Object {

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
//        journal.get_file_record (path, record);
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
//        var xattr_vfs = new Common.AbstractVfs (create_vfs_from_plugin (Common.AbstractVfs.XAttr).release ());
//        folder.sync_engine.sync_file_status_tracker.signal_file_status_changed.connect (
//            xattr_vfs.on_signal_file_status_changed
//        );
//        folder.switch_to_vfs (xattr_vfs);

//        // Using this directly doesn't recursively unpin everything and instead leaves
//        // the files in the hydration that that they on_signal_start with
//        folder.sync_journal ().internal_pin_states.set_for_path ("", PinState.UNSPECIFIED);

//        return xattr_vfs;
//    }

} // class AbstractTestSyncXAttr

} // namespace Testing
} // namespace Occ
