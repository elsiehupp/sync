/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public abstract class AbstractTestSyncMove : GLib.Object {

    protected class OperationCounter {
        public int number_of_get = 0;
        public int number_of_put = 0;
        public int number_of_move = 0;
        public int number_of_delete = 0;

        public void on_signal_reset () {
            this.number_of_get = 0;
            this.number_of_put = 0;
            this.number_of_move = 0;
            this.number_of_delete = 0;
        }

        public void functor (Soup.Operation operation, Soup.Request request, QIODevice device) {
            if (operation == Soup.GetOperation)
                ++number_of_get;
            if (operation == Soup.PutOperation)
                ++number_of_put;
            if (operation == Soup.DeleteOperation)
                ++number_of_delete;
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "MOVE")
                ++number_of_move;
            return null;
        }
    }


    protected static bool item_successful (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
        var item = spy.find_item (path);
        return item.status == SyncFileItem.Status.SUCCESS && item.instruction == instr;
    }


    protected static bool item_conflict (ItemCompletedSpy spy, string path) {
        var item = spy.find_item (path);
        return item.status == SyncFileItem.Status.CONFLICT && item.instruction == CSync.SyncInstructions.CONFLICT;
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
        if (!base_path)
            return false;
        foreach (var item in base_path.children) {
            if (item.name.has_prefix (path_components.filename ()) && item.name.contains (" (conflicted copy")) {
                local.remove (item.path);
                return true;
            }
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private static string get_name (Common.AbstractVfs.Mode vfs_mode, string s) {
        if (vfs_mode == AbstractVfs.WithSuffix) {
            return s + APPLICATION_DOTVIRTUALFILE_SUFFIX;
        }
        return s;
    }

} // class AbstractTestSyncMove

} // namespace Testing
} // namespace Occ
