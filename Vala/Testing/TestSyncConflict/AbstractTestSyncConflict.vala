/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestSyncConflict : GLib.Object {

    protected static void clean_up (ItemCompletedSpy complete_spy) {
        complete_spy = "";
    }


    protected static bool item_successful (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
        var item = spy.find_item (path);
        return item.status == LibSync.SyncFileItem.Status.SUCCESS && item.instruction == instr;
    }


    protected static bool item_conflict (ItemCompletedSpy spy, string path) {
        var item = spy.find_item (path);
        return item.status == LibSync.SyncFileItem.Status.CONFLICT && item.instruction == CSync.SyncInstructions.CONFLICT;
    }


    protected static bool item_successful_move (ItemCompletedSpy spy, string path) {
        return item_successful (spy, path, CSync.SyncInstructions.RENAME);
    }


    protected static GLib.List<string> find_conflicts (FileInfo directory) {
        GLib.List<string> conflicts;
        foreach (var item in directory.children) {
            if (item.name.contains (" (conflicted copy")) {
                conflicts.append (item.path);
            }
        }
        return conflicts;
    }


    protected static bool expect_and_wipe_conflict (AbstractFileModifier local, FileInfo state, string path) {
        PathComponents path_components = new PathComponents (path);
        var base_path = state.find (path_components.parent_directory_components ());
        if (!base_path) {
            return false;
        }
        foreach (var item in base_path.children) {
            if (item.name.has_prefix (path_components.filename ()) && item.name.contains (" (conflicted copy")) {
                local.remove (item.path);
                return true;
            }
        }
        return false;
    }


    protected static SyncJournalFileRecord database_record (FakeFolder folder, string path) {
        SyncJournalFileRecord record;
        folder.sync_journal ().get_file_record (path, record);
        return record;
    }

} // class AbstractTestSyncConflict

} // namespace Testing
} // namespace Occ
