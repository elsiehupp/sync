/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QRegularExpression>
//  #includeonce
//  #include <QRegularExpression>
//  #include <chrono>

namespace Occ {
namespace LibSync {

/***********************************************************
Value class containing the options given to the sync engine
***********************************************************/
public class SyncOptions : GLib.Object {

    /***********************************************************
    Maximum size (in Bytes) a folder can have without asking
    for confirmation.

    -1 means infinite
    ***********************************************************/
    public int64 new_big_folder_size_limit = -1;

    /***********************************************************
    If a confirmation should be asked for external storages
    ***********************************************************/
    public bool confirm_external_storage = false;

    /***********************************************************
    If remotely deleted files are needed to move to trash
    ***********************************************************/
    public bool move_files_to_trash = false;

    /***********************************************************
    Create a virtual file for new files instead of downloading.
    May not be null
    ***********************************************************/
    public unowned Vfs vfs;

    /***********************************************************
    The initial un-adjusted chunk size in bytes for chunked
    uploads, both for old and new chunking algorithm, which
    classifies the item to be chunked

    In chunking_nG, when dynamic chunk size adjustments are d
    starting value and is then gradually adjusted within the
    min_chunk_size / max_chunk_size bounds.
    ***********************************************************/
    public int64 initial_chunk_size = 10 * 1000 * 1000; // 10MB

    /***********************************************************
    The minimum chunk size in bytes for chunked uploads
    ***********************************************************/
    public int64 min_chunk_size = 1 * 1000 * 1000; // 1MB

    /***********************************************************
    The maximum chunk size in bytes for chunked uploads
    ***********************************************************/
    public int64 max_chunk_size = 1000 * 1000 * 1000; // 1000MB

    /***********************************************************
    The target duration of chunk uploads for dynamic chunk sizing.

    Set to 0 it will disable dynamic chunk sizing.
    ***********************************************************/
    public GLib.TimeSpan target_chunk_upload_duration = std.chrono.minutes (1);

    /***********************************************************
    The maximum number of active jobs in parallel
    ***********************************************************/
    public int parallel_network_jobs = 6;

    /***********************************************************
    Only sync files that match the expression
    Invalid pattern by default.
    A regular expression to match file names
    If no pattern is provided the default is an invalid regular
    expression.
    ***********************************************************/
    public QRegularExpression file_regex { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public SyncOptions () {
        this.vfs = new VfsOff ();
        this.file_regex = QRegularExpression ("(");
    }


    /***********************************************************
    Reads settings from env vars where available.

    Currently reads
        this.initial_chunk_size,
        this.min_chunk_size,
        this.max_chunk_size,
        this.target_chunk_upload_duration,
        this.parallel_network_jobs.
    ***********************************************************/
    public void fill_from_environment_variables () {
        string chunk_size_env = qgetenv ("OWNCLOUD_CHUNK_SIZE");
        if (!chunk_size_env == "")
            this.initial_chunk_size = chunk_size_env.to_u_int ();

        string min_chunk_size_env = qgetenv ("OWNCLOUD_MIN_CHUNK_SIZE");
        if (!min_chunk_size_env == "")
            this.min_chunk_size = min_chunk_size_env.to_u_int ();

        string max_chunk_size_env = qgetenv ("OWNCLOUD_MAX_CHUNK_SIZE");
        if (!max_chunk_size_env == "")
            this.max_chunk_size = max_chunk_size_env.to_u_int ();

        string target_chunk_upload_duration_env = qgetenv ("OWNCLOUD_TARGET_CHUNK_UPLOAD_DURATION");
        if (!target_chunk_upload_duration_env == "")
            this.target_chunk_upload_duration = GLib.TimeSpan (target_chunk_upload_duration_env.to_u_int ());

        int max_parallel = qgetenv ("OWNCLOUD_MAX_PARALLEL").to_int ();
        if (max_parallel > 0)
            this.parallel_network_jobs = max_parallel;
    }


    /***********************************************************
    Ensure min <= initial <= max

    Previously min/max chunk size values didn't exist, so users
    might have setups where the chunk size exceeds the new
    min/max default values. To cope with this, adjust min/max
    to always include the initial chunk size value.
    ***********************************************************/
    public void verify_chunk_sizes () {
        this.min_chunk_size = q_min (this.min_chunk_size, this.initial_chunk_size);
        this.max_chunk_size = q_max (this.max_chunk_size, this.initial_chunk_size);
    }


    /***********************************************************
    A pattern like *.txt, matching only file names
    ***********************************************************/
    public void file_pattern (string pattern) {
        // full match or a path ending with this pattern
        path_pattern (" (^|/|\\\\)" + pattern + '$');
    }


    /***********************************************************
    A pattern like /own.*\/.*txt matching the full path
    ***********************************************************/
    public void path_pattern (string pattern) {
        this.file_regex.pattern_options (Utility.fs_case_preserving () ? QRegularExpression.CaseInsensitiveOption : QRegularExpression.NoPatternOption);
        this.file_regex.pattern (pattern);
    }

} // class SyncOptions

} // namespace LibSync
} // namespace Occ
