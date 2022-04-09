namespace Occ {
namespace LibSync {

/***********************************************************
@class DiscoverySingleLocalDirectoryJob

@brief Run list on a local directory and process the results
for Discovery

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class DiscoverySingleLocalDirectoryJob : GLib.Object /*, GLib.Runnable*/ {

    /***********************************************************
    ***********************************************************/
    private string local_path;
    private unowned Account account;
    private AbstractVfs vfs;


    internal signal void signal_finished (GLib.List<LocalInfo> result);
    internal signal void finished_fatal_error (string error_string);
    internal signal void finished_non_fatal_error (string error_string);

    internal signal void signal_item_discovered (unowned SyncFileItem item);
    internal signal void child_ignored (bool b);

    /***********************************************************
    ***********************************************************/
    public DiscoverySingleLocalDirectoryJob.for_account (unowned Account account, string local_path, AbstractVfs vfs, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.local_path = local_path;
        this.account = account;
        this.vfs = vfs;
        q_register_meta_type<GLib.List<LocalInfo> > ("GLib.List<LocalInfo>");
    }


    /***********************************************************
    Use as GLib.Runnable
    ***********************************************************/
    public void run () {
        string local_path = this.local_path;
        if (local_path.has_suffix ("/")) // Happens if this.current_folder.local == ""
            local_path.chop (1);

        var dh = CSync.VioHandle.open_directory (local_path);
        if (!dh) {
            GLib.info ("Error while opening directory" + local_path + errno.to_string ());
            string error_string = _("Error while opening directory %1").printf (local_path);
            if (errno == EACCES) {
                error_string = _("Directory not accessible on client, permission denied");
                /* emit */ finished_non_fatal_error (error_string);
                return;
            } else if (errno == ENOENT) {
                error_string = _("Directory not found : %1").printf (local_path);
            } else if (errno == ENOTDIR) {
                // Not a directory..
                // Just consider it is empty
                return;
            }
            /* emit */ finished_fatal_error (error_string);
            return;
        }

        GLib.List<LocalInfo> results;
        while (true) {
            errno = 0;
            var dirent = CSync.VioHandle.read_directory (dh, this.vfs);
            if (!dirent)
                break;
            if (dirent.type == ItemType.SKIP)
                continue;
            LocalInfo i;
            static GMime.Encoding codec = GMime.Encoding.codec_for_name ("UTF-8");
            //  ASSERT (codec);
            GMime.Encoding.ConverterState state;
            i.name = codec.to_unicode (dirent.path, dirent.path.size (), state);
            if (state.invalid_chars > 0 || state.remaining_chars > 0) {
                /* emit */ child_ignored (true);
                var item = unowned new SyncFileItem ();
                //item.file = this.current_folder.target + i.name;
                // FIXME ^^ do we really need to use this.target or is local fine?
                item.file = this.local_path + i.name;
                item.instruction = CSync.SyncInstructions.IGNORE;
                item.status = SyncFileItem.Status.NORMAL_ERROR;
                item.error_string = _("Filename encoding is not valid");
                /* emit */ signal_item_discovered (item);
                continue;
            }
            i.modtime = dirent.modtime;
            i.size = dirent.size;
            i.inode = dirent.inode;
            i.is_directory = dirent.type == ItemType.DIRECTORY;
            i.is_hidden = dirent.is_hidden;
            i.is_sym_link = dirent.type == ItemType.SOFT_LINK;
            i.is_virtual_file = dirent.type == ItemType.VIRTUAL_FILE || dirent.type == ItemType.VIRTUAL_FILE_DOWNLOAD;
            i.type = dirent.type;
            results.push_back (i);
        }
        if (errno != 0) {
            CSync.VioHandle.close_directory (dh);

            // Note: Windows vio converts any error into EACCES
            GLib.warning ("readdir failed for file in " + local_path + " - errno: " + errno.to_string ());
            /* emit */ finished_fatal_error (_("Error while reading directory %1").printf (local_path));
            return;
        }

        errno = 0;
        CSync.VioHandle.close_directory (dh);
        if (errno != 0) {
            GLib.warning ("closedir failed for file in " + local_path + " - errno: " + errno.to_string ());
        }

        /* emit */ signal_finished (results);
    }

} // class DiscoverySingleLocalDirectoryJob

} // namespace LibSync
} // namespace Occ
