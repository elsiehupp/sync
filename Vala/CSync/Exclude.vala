

//  #include <qglobal.h>

//  #ifndef GNU_SOURCE
//  const int GNU_SOURCE
//  #endif

//  #include <GLib.FileInfo>
//  #include <GLib.Dir>

//  #include <QRegularExpression>
//  #include <functional>

namespace CSync {

/***********************************************************
@class ExcludedFiles

@brief Manages file/directory exclusion.

Most commonly exclude patterns are loaded from file
add_exclude_file_path and on_signal_reload_exclude_files ().

Excluded files are primarily relevant for sync runs, and for
file watcher filtering.

Excluded files and ignored files are the same thing. But the
selective sync blocklist functionality is a different thing
entirely.

libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.org>

@copyright LGPL 2.1 or later
***********************************************************/
public class ExcludedFiles : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public class Version : std.tuple<int, int, int> { }

    /***********************************************************
    Our BasePath need to end with '/'
    ***********************************************************/
    private class BasePathString : string {
        public BasePathString (string other) {
            base (std.move (other));
            //  Q_ASSERT (ends_with ('/'));
        }

        public BasePathString (string other) {
            base (other);
            //  Q_ASSERT (ends_with ('/'));
        }
    }

    /***********************************************************
    ***********************************************************/
    public enum Type {
        NOT_EXCLUDED   = 0,
        EXCLUDE_SILENT,
        AND_REMOVE,
        LIST,
        INVALID_CHAR,
        TRAILING_SPACE,
        LONG_FILENAME,
        HIDDEN,
        STAT_FAILED,
        CONFLICT,
        CANNOT_ENCODE,
        SERVER_BLOCKLISTED,
    }


    // See http://support.microsoft.com/kb/74496 and
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247 (v=vs.85).aspx
    // Additionally, we ignore '$Recycle.Bin', see https://github.com/owncloud/client/issues/2955
    const string win_reserved_words_3[] = {
        "CON",
        "PRN",
        "AUX",
        "NUL"
    };


    const string win_reserved_words_4[] = {
        "COM1",
        "COM2",
        "COM3",
        "COM4",
        "COM5",
        "COM6",
        "COM7",
        "COM8",
        "COM9",
        "LPT1",
        "LPT2",
        "LPT3",
        "LPT4",
        "LPT5",
        "LPT6",
        "LPT7",
        "LPT8",
        "LPT9"
    };


    const string win_reserved_words_n[] = {
        "CLOCK$",
        "$Recycle.Bin"
    };

    /***********************************************************
    ***********************************************************/
    private string local_path;

    /***********************************************************
    Files to load excludes from
    ***********************************************************/
    private GLib.HashTable<BasePathString, string[]> exclude_files;

    /***********************************************************
    Exclude patterns added with add_manual_exclude ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, string[]> manual_excludes;

    /***********************************************************
    List of all active exclude patterns
    ***********************************************************/
    private GLib.HashTable<BasePathString, string[]> all_excludes;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> bname_traversal_regex_file;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> bname_traversal_regex_dir;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> full_traversal_regex_file;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> full_traversal_regex_dir;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> full_regex_file;

    /***********************************************************
    see prepare ()
    ***********************************************************/
    private GLib.HashTable<BasePathString, QRegularExpression> full_regex_dir;

    /***********************************************************
    ***********************************************************/
    private bool exclude_conflict_files = true;


    /***********************************************************
    Whether * and ? in patterns can match a /

    Unfortunately this was how matching was done on Windows so
    it continues to be enabled there.
    ***********************************************************/
    private bool wildcards_match_slash = false;

    /***********************************************************
    The client version. Used to evaluate version-dependent excludes,
    see version_directive_keep_next_line ().
    ***********************************************************/
    private Version client_version;

    /***********************************************************
    ***********************************************************/
    //  private friend class AbstractTestCSyncExclude;

    /***********************************************************
    ***********************************************************/
    public ExcludedFiles (string local_path = "/") {
        this.local_path = local_path;
        this.client_version = { MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR, MIRALL_VERSION_PATCH };
        //  Q_ASSERT (this.local_path.ends_with ("/"));
        // Windows used to use PathMatchSpec which allows foo to match abc/deffoo.
        this.wildcards_match_slash = Utility.is_windows ();

        // We're in a detached exclude probably coming from a partial sync or test
        if (this.local_path == "") {
            return;
        }
    }


    /***********************************************************
    Adds a new path to a file containing exclude patterns.

    Does not load the file. Use on_signal_reload_exclude_files () afterwards.
    ***********************************************************/
    public void add_exclude_file_path (string path) {
        const GLib.FileInfo exclude_file_info = new GLib.FileInfo (path);
        const var filename = exclude_file_info.filename ();
        const var base_path = filename.compare ("sync-exclude.lst", Qt.CaseInsensitive) == 0
                                                                        ? this.local_path
                                                                        : left_include_last (path, '/');
        var exclude_files_local_path = this.exclude_files[base_path];
        if (std.find (exclude_files_local_path.cbegin (), exclude_files_local_path.cend (), path) == exclude_files_local_path.cend ()) {
            exclude_files_local_path.append (path);
        }
    }


    /***********************************************************
    Whether conflict files shall be excluded.

    Defaults to true.
    ***********************************************************/
    public void exclude_conflict_files (bool value) {
        this.exclude_conflict_files = value;
    }


    /***********************************************************
    Checks whether a file or directory should be excluded.

    @param file_path     the absolute path to the file
    @param base_path     folder path from which to apply exclude rules, ends with a /
    ***********************************************************/
    public bool is_excluded (
        string file_path,
        string base_path,
        bool exclude_hidden) {
        if (!file_path.starts_with (base_path, Utility.fs_case_preserving () ? Qt.CaseInsensitive : Qt.CaseSensitive)) {
            // Mark paths we're not responsible for as excluded...
            return true;
        }

        //TODO this seems a waste, hidden files are ignored before hitting this function it seems
        if (exclude_hidden) {
            string path = file_path;
            // Check all path subcomponents, but to not* check the base path:
            // We do want to be able to sync with a hidden folder as the target.
            while (path.size () > base_path.size ()) {
                GLib.FileInfo file_info = new GLib.FileInfo (path);
                if (file_info.filename () != ".sync-exclude.lst"
                    && (file_info.is_hidden () || file_info.filename ().starts_with ('.'))) {
                    return true;
                }

                // Get the parent path
                path = file_info.absolute_path;
            }
        }

        GLib.FileInfo file_info = new GLib.FileInfo (file_path);
        ItemType type = ItemType.FILE;
        if (file_info.is_dir ()) {
            type = ItemType.DIRECTORY;
        }

        string relative_path = file_path.mid (base_path.size ());
        if (relative_path.ends_with ('/')) {
            relative_path.chop (1);
        }

        return full_pattern_match (relative_path, type) != CSync.ExcludedFiles.Type.NOT_EXCLUDED;
    }


    /***********************************************************
    Adds an exclude pattern anchored to base path

    Primarily used in tests. Patterns added this way are preserved when
    on_signal_reload_exclude_files () is called.
    ***********************************************************/
    public void add_manual_exclude (string expr) {
        add_manual_exclude_with_base_path (expr, this.local_path);
    }


    /***********************************************************
    ***********************************************************/
    public void add_manual_exclude_with_base_path (string expr, string base_path) {
        //  Q_ASSERT (base_path.ends_with ('/'));

        var key = base_path;
        this.manual_excludes[key].append (expr);
        this.all_excludes[key].append (expr);
        prepare (key);
    }


    /***********************************************************
    Removes all manually added exclude patterns.

    Primarily used in tests.
    ***********************************************************/
    public void clear_manual_excludes () {
        this.manual_excludes.clear ();
        on_signal_reload_exclude_files ();
    }


    /***********************************************************
    Adjusts behavior of wildcards. Only used for testing.
    ***********************************************************/
    public void wildcards_match_slash (bool value) {
        this.wildcards_match_slash = value;
        prepare ();
    }


    /***********************************************************
    Sets the client version, only used for testing.
    ***********************************************************/
    public void client_version (Version version) {
        this.client_version = version;
    }


    /***********************************************************
    @brief Check if the given path should be excluded in a traversal situation.

    It does only part of the work that full () does because it's as
    that all leading directories have been run
    before. This can be significantly faster.

    That means for 'foo/bar/file' only ('foo/bar/file', 'file')
    against the exclude patterns.

    @param Path is folder-relative, should not on_signal_start with a /.

    Note that this only matches patterns. It does not check whether the file
    or directory pointed to is hidden (or whether it even exists).
    ***********************************************************/
    public CSyncExcludeType traversal_pattern_match (string path, ItemType filetype) {
        var match = this.csync_excluded_common (path, this.exclude_conflict_files);
        if (match != CSync.ExcludedFiles.Type.NOT_EXCLUDED)
            return match;
        if (this.all_excludes == "")
            return CSync.ExcludedFiles.Type.NOT_EXCLUDED;

        // Directories are guaranteed to be visited before their files
        if (filetype == ItemType.DIRECTORY) {
            const string base_path = this.local_path + path + '/';
            const string absolute_path = base_path + ".sync-exclude.lst";
            GLib.FileInfo exclude_file_info = new GLib.FileInfo (absolute_path);

            if (exclude_file_info.is_readable ()) {
                add_exclude_file_path (absolute_path);
                on_signal_reload_exclude_files ();
            } else {
                GLib.warning ("System exclude list file could not be read: " + absolute_path);
            }
        }

        // Check the bname part of the path to see whether the full
        // regular_expression should be run.
        QStringRef bname_str = new QStringRef (path);
        int last_slash = path.last_index_of ('/');
        if (last_slash >= 0) {
            bname_str = path.mid_ref (last_slash + 1);
        }

        string base_path = this.local_path + path;
        while (base_path.size () > this.local_path.size ()) {
            base_path = left_include_last (base_path, '/');
            QRegularExpressionMatch regular_expression_match;
            if (filetype == ItemType.DIRECTORY
                && this.bname_traversal_regex_dir.contains (base_path)) {
                regular_expression_match = this.bname_traversal_regex_dir[base_path].match (bname_str);
            } else if (filetype == ItemType.FILE
                && this.bname_traversal_regex_file.contains (base_path)) {
                regular_expression_match = this.bname_traversal_regex_file[base_path].match (bname_str);
            } else {
                continue;
            }

            if (!regular_expression_match.has_match ())
                return CSync.ExcludedFiles.Type.NOT_EXCLUDED;
            if (regular_expression_match.captured_start ("exclude") != -1) {
                return CSync.ExcludedFiles.Type.LIST;
            } else if (regular_expression_match.captured_start ("excluderemove") != -1) {
                return CSync.ExcludedFiles.Type.AND_REMOVE;
            }
        }

        // third capture: full path matching is triggered
        base_path = this.local_path + path;
        while (base_path.size () > this.local_path.size ()) {
            base_path = left_include_last (base_path, '/');
            QRegularExpressionMatch regular_expression_match;
            if (filetype == ItemType.DIRECTORY
                && this.full_traversal_regex_dir.contains (base_path)) {
                regular_expression_match = this.full_traversal_regex_dir[base_path].match (path);
            } else if (filetype == ItemType.FILE
                && this.full_traversal_regex_file.contains (base_path)) {
                regular_expression_match = this.full_traversal_regex_file[base_path].match (path);
            } else {
                continue;
            }

            if (regular_expression_match.has_match ()) {
                if (regular_expression_match.captured_start ("exclude") != -1) {
                    return CSync.ExcludedFiles.Type.LIST;
                } else if (regular_expression_match.captured_start ("excluderemove") != -1) {
                    return CSync.ExcludedFiles.Type.AND_REMOVE;
                }
            }
        }
        return CSync.ExcludedFiles.Type.NOT_EXCLUDED;
    }


    /***********************************************************
    Reloads the exclude patterns from the registered paths.
    ***********************************************************/
    public bool on_signal_reload_exclude_files () {
        this.all_excludes.clear ();
        // clear all regular_expression
        this.bname_traversal_regex_file.clear ();
        this.bname_traversal_regex_dir.clear ();
        this.full_traversal_regex_file.clear ();
        this.full_traversal_regex_dir.clear ();
        this.full_regex_file.clear ();
        this.full_regex_dir.clear ();

        bool on_signal_success = true;
        const var keys = this.exclude_files.keys ();
        foreach (var base_path in keys) {
            foreach (var exclude_file in this.exclude_files.value (base_path)) {
                GLib.File file = GLib.File.new_for_path (exclude_file);
                if (file.exists () && file.open (QIODevice.ReadOnly)) {
                    on_signal_load_exclude_file_patterns (base_path, file);
                } else {
                    on_signal_success = false;
                    GLib.warning ("System exclude list file could not be opened: " + exclude_file);
                }
            }
        }

        var end_manual = this.manual_excludes.cend ();
        for (var kv = this.manual_excludes.cbegin (); kv != end_manual; ++kv) {
            this.all_excludes[kv.key ()].append (kv.value ());
            prepare (kv.key ());
        }

        return on_signal_success;
    }


    /***********************************************************
    Loads the exclude patterns from file the registered base paths.
    ***********************************************************/
    public void on_signal_load_exclude_file_patterns (string base_path, GLib.File file) {
        string[] patterns;
        while (!file.at_end ()) {
            string line = file.read_line ().trimmed ();
            if (line.starts_with ("#!version")) {
                if (!version_directive_keep_next_line (line))
                    file.read_line ();
            }
            if (line == "" || line.starts_with ('#'))
                continue;
            csync_exclude_expand_escapes (line);
            patterns.append (string.from_utf8 (line));
        }
        this.all_excludes[base_path].append (patterns);

        // nothing to prepare if the user decided to not exclude anything
        if (!this.all_excludes.value (base_path) == "") {
            prepare (base_path);
        }
    }


    /***********************************************************
    Returns true if the version directive indicates the next line
    should be skipped.

    A version directive has the form "#!version <operation> <version>"
    where <operation> c
    like 2.5.

    Example:

    #!version < 2.5.0
    myexclude

    Would enable the "myexclude" pattern only for versions before 2.5.0.
    ***********************************************************/
    private bool version_directive_keep_next_line (string directive) {
        if (!directive.starts_with ("#!version"))
            return true;
        QByteArrayList args = directive.split (' ');
        if (args.size () != 3)
            return true;
        string operation = args[1];
        QByteArrayList arg_versions = args[2].split ('.');
        if (arg_versions.size () != 3)
            return true;

        var arg_version = std.make_tuple (arg_versions[0].to_int (), arg_versions[1].to_int (), arg_versions[2].to_int ());
        if (operation == "<=")
            return this.client_version <= arg_version;
        if (operation == "<")
            return this.client_version < arg_version;
        if (operation == ">")
            return this.client_version > arg_version;
        if (operation == ">=")
            return this.client_version >= arg_version;
        if (operation == "==")
            return this.client_version == arg_version;
        return true;
    }


    /***********************************************************
    @brief Match the exclude pattern against the full path.

    @param Path is folder-relative, should not on_signal_start with a /.

    Note that this only matches patterns. It does not check whether the file
    or directory pointed to is hidden (or whether it even exists).
    ***********************************************************/
    private CSyncExcludeType full_pattern_match (string path, ItemType filetype) {
        var match = this.csync_excluded_common (p, this.exclude_conflict_files);
        if (match != CSync.ExcludedFiles.Type.NOT_EXCLUDED)
            return match;
        if (this.all_excludes == "")
            return CSync.ExcludedFiles.Type.NOT_EXCLUDED;

        // `path` seems to always be relative to `this.local_path`, the tests however have not been
        // written that way... this makes the tests happy for now. TODO Fix the tests at some point
        string path = p;
        if (path.starts_with (this.local_path)) {
            path = path.mid (this.local_path.size ());
        }

        string base_path = this.local_path + path;
        while (base_path.size () > this.local_path.size ()) {
            base_path = left_include_last (base_path, '/');
            QRegularExpressionMatch regular_expression_match;
            if (filetype == ItemType.DIRECTORY
                && this.full_regex_dir.contains (base_path)) {
                regular_expression_match = this.full_regex_dir[base_path].match (p);
            } else if (filetype == ItemType.FILE
                && this.full_regex_file.contains (base_path)) {
                regular_expression_match = this.full_regex_file[base_path].match (p);
            } else {
                continue;
            }

            if (regular_expression_match.has_match ()) {
                if (regular_expression_match.captured_start ("exclude") != -1) {
                    return CSync.ExcludedFiles.Type.LIST;
                } else if (regular_expression_match.captured_start ("excluderemove") != -1) {
                    return CSync.ExcludedFiles.Type.AND_REMOVE;
                }
            }
        }

        return CSync.ExcludedFiles.Type.NOT_EXCLUDED;
    }


    /***********************************************************
    Generate optimized regular expressions for the exclude patterns anchored to base_path.

    The optimization works in two steps : First, all supported patterns are put
    into full_regex_file/full_regex_dir. These regexes
    path to determine whether it is excluded or not.

    The second is a performance optimization. The particularly common use
    case for excludes during
    the full path every time, we check each parent path with the traversal
    function incrementally.

    Example: When the sync run eventually arrives at "a/b/c it can assume
    that the traversal m
    and just needs to run the traversal matcher on "a/b/c".

    The full matcher is equivalent to or-combining the traversal match resul
    of all parent paths:
      full ("a/b/c/d") == traversal (

    The traversal matcher can be extremely fast because it has a fast early-
    case : It checks the bname part of the path against bname_traversal_regex
    and only runs a simplified full_traversal_regex on the whole path if bname
    activation for it was triggered.

    Note: The traversal matcher will return not-excluded on some paths that
    full matcher would exclude. Example: "b" is excluded. traversal ("b/c")
    returns not-excluded because "c" isn't a bname activation pattern.
    ***********************************************************/
    private void prepare_with_base_path (BasePathString base_path) {
        //  Q_ASSERT (this.all_excludes.contains (base_path));

        // Build regular expressions for the different cases.
        //
        // To compose the this.bname_traversal_regex, this.full_traversal_regex and this.full_regex
        // patterns we collect several subgroups of patterns here.
        //
        // * The "full" group will contain all patterns that contain a non-trailing
        //   slash. They only make sense in the full_regex and full_traversal_regex.
        // * The "bname" group contains all patterns without a non-trailing slash.
        //   These need separate handling in the this.full_regex (slash-containing
        //   patterns must be anchored to the front, these don't need it)
        // * The "bname_trigger" group contains the bname part of all patterns in the
        //   "full" group. These and the "bname" group become this.bname_traversal_regex.
        //
        // To complicate matters, the exclude patterns have two binary attributes
        // meaning we'll end up with 4 variants:
        // * "]" patterns mean "EXCLUDE_AND_REMOVE", they get collected in the
        //   pattern strings ending in "Remove". The others go to "Keep".
        // * trailing-slash patterns match directories only. They get collected
        //   in the pattern strings saying "Dir", the others go into "FileDir"
        //   because they match files and directories.

        string full_file_dir_keep;
        string full_file_dir_remove;
        string full_dir_keep;
        string full_dir_remove;

        string bname_file_dir_keep;
        string bname_file_dir_remove;
        string bname_dir_keep;
        string bname_dir_remove;

        string bname_trigger_file_dir;
        string bname_trigger_dir;

        foreach (var exclude in this.all_excludes.value (base_path)) {
            if (exclude[0] == '\n') {
                continue; // empty line
            }
            if (exclude[0] == '\r') {
                continue; // empty line
            }

            bool match_dir_only = exclude.ends_with ('/');
            if (match_dir_only) {
                exclude = exclude.left (exclude.size () - 1);
            }

            bool remove_excluded = (exclude[0] == ']');
            if (remove_excluded) {
                exclude = exclude.mid (1);
            }

            bool full_path = exclude.contains ('/');

            /* Use QRegularExpression, append to the right pattern */
            var bname_file_dir = remove_excluded ? bname_file_dir_remove : bname_file_dir_keep;
            var bname_dir = remove_excluded ? bname_dir_remove : bname_dir_keep;
            var full_file_dir = remove_excluded ? full_file_dir_remove : full_file_dir_keep;
            var full_dir = remove_excluded ? full_dir_remove : full_dir_keep;

            if (full_path) {
                // The full pattern is matched against a path relative to this.local_path, however exclude is
                // relative to base_path at this point.
                // We know for sure that both this.local_path and base_path are absolute and that base_path is
                // contained in this.local_path. So we can simply remove it from the begining.
                var rel_path = base_path.mid (this.local_path.size ());
                // Make exclude relative to this.local_path
                exclude.prepend (rel_path);
            }
            var regex_exclude = convert_to_regexp_syntax (exclude, this.wildcards_match_slash);
            if (!full_path) {
                regex_append (bname_file_dir, bname_dir, regex_exclude, match_dir_only);
            } else {
                regex_append (full_file_dir, full_dir, regex_exclude, match_dir_only);

                // For activation, trigger on the 'bname' part of the full pattern.
                string bname_exclude = extract_bname_trigger (exclude, this.wildcards_match_slash);
                var regex_bname = convert_to_regexp_syntax (bname_exclude, true);
                regex_append (bname_trigger_file_dir, bname_trigger_dir, regex_bname, match_dir_only);
            }
        }

        empty_match_nothing (full_file_dir_keep);
        empty_match_nothing (full_file_dir_remove);
        empty_match_nothing (full_dir_keep);
        empty_match_nothing (full_dir_remove);

        empty_match_nothing (bname_file_dir_keep);
        empty_match_nothing (bname_file_dir_remove);
        empty_match_nothing (bname_dir_keep);
        empty_match_nothing (bname_dir_remove);

        empty_match_nothing (bname_trigger_file_dir);
        empty_match_nothing (bname_trigger_dir);

        // The bname regular_expression is applied to the bname only, so it must be
        // anchored in the beginning and in the end. It has the structure:
        // (exclude)| (excluderemove)| (bname triggers).
        // If the third group matches, the full_activated_regex needs to be applied
        // to the full path.
        this.bname_traversal_regex_file[base_path].pattern (
            "^ (?P<exclude>%1)$|"
            + "^ (?P<excluderemove>%2)$|"
            + "^ (?P<trigger>%3)$"
                .printf (bname_file_dir_keep, bname_file_dir_remove, bname_trigger_file_dir));
        this.bname_traversal_regex_dir[base_path].pattern (
            "^ (?P<exclude>%1|%2)$|"
            + "^ (?P<excluderemove>%3|%4)$|"
            + "^ (?P<trigger>%5|%6)$"
                .printf (bname_file_dir_keep, bname_dir_keep, bname_file_dir_remove, bname_dir_remove, bname_trigger_file_dir, bname_trigger_dir));

        // The full traveral regular_expression is applied to the full path if the trigger capture of
        // the bname regular_expression matches. Its basic form is (exclude)| (excluderemove)".
        // This pattern can be much simpler than full_regex since we can assume a traversal
        // situation and doesn't need to look for bname patterns in parent paths.
        this.full_traversal_regex_file[base_path].pattern (
            // Full patterns are anchored to the beginning
            "^ (?P<exclude>%1) (?:$|/)"
            + "|"
            + "^ (?P<excluderemove>%2) (?:$|/)"
                .printf (full_file_dir_keep, full_file_dir_remove));
        this.full_traversal_regex_dir[base_path].pattern (
            "^ (?P<exclude>%1|%2) (?:$|/)"
            + "|"
            + "^ (?P<excluderemove>%3|%4) (?:$|/)"
                .printf (full_file_dir_keep, full_dir_keep, full_file_dir_remove, full_dir_remove));

        // The full regular_expression is applied to the full path and incorporates both bname and
        // full-path patterns. It has the form " (exclude)| (excluderemove)".
        this.full_regex_file[base_path].pattern (
            " (?P<exclude>"
            // Full patterns are anchored to the beginning
            + "^ (?:%1) (?:$|/)|"
            // Simple bname patterns can be any path component
            + " (?:^|/) (?:%2) (?:$|/)|"
            // When checking a file for exclusion we must check all parent paths
            // against the directory-only patterns as well.
            + " (?:^|/) (?:%3)/)"
            + "|"
            + " (?P<excluderemove>"
            + "^ (?:%4) (?:$|/)|"
            + " (?:^|/) (?:%5) (?:$|/)|"
            + " (?:^|/) (?:%6)/)"
                .printf (full_file_dir_keep, bname_file_dir_keep, bname_dir_keep, full_file_dir_remove, bname_file_dir_remove, bname_dir_remove));
        this.full_regex_dir[base_path].pattern (
            " (?P<exclude>"
            + "^ (?:%1|%2) (?:$|/)|"
            + " (?:^|/) (?:%3|%4) (?:$|/))"
            + "|"
            + " (?P<excluderemove>"
            + "^ (?:%5|%6) (?:$|/)|"
            + " (?:^|/) (?:%7|%8) (?:$|/))"
                .printf (full_file_dir_keep, full_dir_keep, bname_file_dir_keep, bname_dir_keep, full_file_dir_remove, full_dir_remove, bname_file_dir_remove, bname_dir_remove));

        QRegularExpression.PatternOptions pattern_options = QRegularExpression.NoPatternOption;
        if (Utility.fs_case_preserving ()) {
            pattern_options |= QRegularExpression.CaseInsensitiveOption;
        }
        this.bname_traversal_regex_file[base_path].pattern_options (pattern_options);
        this.bname_traversal_regex_file[base_path].optimize ();
        this.bname_traversal_regex_dir[base_path].pattern_options (pattern_options);
        this.bname_traversal_regex_dir[base_path].optimize ();
        this.full_traversal_regex_file[base_path].pattern_options (pattern_options);
        this.full_traversal_regex_file[base_path].optimize ();
        this.full_traversal_regex_dir[base_path].pattern_options (pattern_options);
        this.full_traversal_regex_dir[base_path].optimize ();
        this.full_regex_file[base_path].pattern_options (pattern_options);
        this.full_regex_file[base_path].optimize ();
        this.full_regex_dir[base_path].pattern_options (pattern_options);
        this.full_regex_dir[base_path].optimize ();
    }


    /***********************************************************
    ***********************************************************/
    private void prepare () {
        // clear all regular_expression
        this.bname_traversal_regex_file.clear ();
        this.bname_traversal_regex_dir.clear ();
        this.full_traversal_regex_file.clear ();
        this.full_traversal_regex_dir.clear ();
        this.full_regex_file.clear ();
        this.full_regex_dir.clear ();

        const var keys = this.all_excludes.keys ();
        foreach (var base_path in keys) {
            prepare (base_path);
        }
    }


    /***********************************************************
    ***********************************************************/
    private static string extract_bname_trigger (string exclude, bool wildcards_match_slash) {
        // We can definitely drop everything to the left of a / - that will never match
        // any bname.
        string pattern = exclude.mid (exclude.last_index_of ('/') + 1);

        // Easy case, nothing else can match a slash, so that's it.
        if (!wildcards_match_slash)
            return pattern;

        // Otherwise it's more complicated. Examples:
        // - "foo*bar" can match "foo_x/Xbar", pattern is "*bar"
        // - "foo*bar*" can match "foo_x/XbarX", pattern is "*bar*"
        // - "foo?bar" can match "foo/bar" but also "foo_xbar", pattern is "*bar"

        // First, skip wildcards on the very right of the pattern
        int i = pattern.size () - 1;
        while (i >= 0 && is_wildcard (pattern[i]))
            --i;

        // Then scan further until the next wildcard that could match a /
        while (i >= 0 && !is_wildcard (pattern[i]))
            --i;

        // Everything to the right is part of the pattern
        pattern = pattern.mid (i + 1);

        // And if there was a wildcard, it starts with a *
        if (i >= 0) {
            pattern.prepend ('*');
        }

        return pattern;
    }


    private static bool is_wildcard (char c) {
        return c == '*' || c == '?';
    }


    /***********************************************************
    FIXME: originally used pass-by-reference; update to use
    returned value instead.
    ***********************************************************/
    private static string regex_append (string file_dir_pattern, string dir_pattern, string append_me, bool dir_only) {
        string pattern = dir_only ? dir_pattern : file_dir_pattern;
        if (!pattern == "") {
            pattern.append ('|');
        }
        pattern.append (append_me);

        return pattern;
    }


    /***********************************************************
    The empty pattern would match everything; change it to match
    nothing.

    FIXME: originally used pass-by-reference; update to use
    returned value instead.
    ***********************************************************/
    private static string empty_match_nothing (string pattern) {
        if (pattern == "") {
            pattern = "a^";
        }
    }


    /***********************************************************
    Expands C-like escape sequences (in place)

    ***********************************************************/
    private static void csync_exclude_expand_escapes (string *input) {
        size_t o = 0;
        char line = input;
        var len = input.size ();
        for (int i = 0; i < len; ++i) {
            if (line[i] == '\\') {
                // at worst input[i+1] is \0
                switch (line[i+1]) {
                case '\'' : line[o++] = '\''; break;
                case '"' : line[o++] = '"'; break;
                case '?' : line[o++] = '?'; break;
                case '#' : line[o++] = '#'; break;
                case 'a' : line[o++] = '\a'; break;
                case 'b' : line[o++] = '\b'; break;
                case 'f' : line[o++] = '\f'; break;
                case 'n' : line[o++] = '\n'; break;
                case 'r' : line[o++] = '\r'; break;
                case 't' : line[o++] = '\t'; break;
                case 'v' : line[o++] = '\v'; break;
                default:
                    // '\*' '\?' '\[' '\\' will be processed during regular_expression translation
                    // '\\' is intentionally not expanded here (to avoid '\\*' and '\*'
                    // ending up meaning the same thing)
                    line[o++] = line[i];
                    line[o++] = line[i + 1];
                    break;
                }
                ++i;
            } else {
                line[o++] = line[i];
            }
        }
        input.resize (Utility.convert_size_to_int (o));
    }


    /***********************************************************
    @brief Checks if filename is considered reserved by Windows
    @param filename filename
    @return true if file is reserved, false otherwise

    ***********************************************************/
    private static bool csync_is_windows_reserved_word (QStringRef filename) {
        size_t len_filename = filename.size ();

        // Drive letters
        if (len_filename == 2 && filename.at (1) == ':') {
            if (filename.at (0) >= 'a' && filename.at (0) <= 'z') {
                return true;
            }
            if (filename.at (0) >= 'A' && filename.at (0) <= 'Z') {
                return true;
            }
        }

        if (len_filename == 3 || (len_filename > 3 && filename.at (3) == '.')) {
            foreach (string word in win_reserved_words_3) {
                if (filename.left (3).compare (word, Qt.CaseInsensitive) == 0) {
                    return true;
                }
            }
        }

        if (len_filename == 4 || (len_filename > 4 && filename.at (4) == '.')) {
            foreach (string word in win_reserved_words_4) {
                if (filename.left (4).compare (word, Qt.CaseInsensitive) == 0) {
                    return true;
                }
            }
        }

        foreach (string word in win_reserved_words_n) {
            if (filename.compare (word, Qt.CaseInsensitive) == 0) {
                return true;
            }
        }

        return false;
    }


    private static CSyncExcludeType csync_excluded_common (string path, bool exclude_conflict_files) {
        /* split up the path */
        QStringRef bname = new QStringRef (path);
        int last_slash = path.last_index_of ('/');
        if (last_slash >= 0) {
            bname = path.mid_ref (last_slash + 1);
        }

        qsizetype blen = bname.size ();
        // 9 = strlen (".sync_.db")
        if (blen >= 9 && bname.at (0) == '.') {
            if (bname.contains (".db")) {
                if (bname.starts_with (".sync_", Qt.CaseInsensitive)  // ".sync_*.db*"
                    || bname.starts_with (".sync_", Qt.CaseInsensitive) // ".sync_*.db*"
                    || bname.starts_with (".csync_journal.db", Qt.CaseInsensitive)) { // ".csync_journal.db*"
                    return CSync.ExcludedFiles.Type.EXCLUDE_SILENT;
                }
            }
            if (bname.starts_with (".owncloudsync.log", Qt.CaseInsensitive)) { // ".owncloudsync.log*"
                return CSync.ExcludedFiles.Type.EXCLUDE_SILENT;
            }
        }

        // check the strlen and ignore the file if its name is longer than 254 chars.
        // whenever changing this also check create_download_temporary_filename
        if (blen > 254) {
            return CSync.ExcludedFiles.Type.LONG_FILENAME;
        }

        /* Do not sync desktop.ini files anywhere in the tree. */
        const var desktop_ini_file = "desktop.ini";
        if (blen == static_cast<qsizetype> (desktop_ini_file.length) && bname.compare (desktop_ini_file, Qt.CaseInsensitive) == 0) {
            return CSync.ExcludedFiles.Type.EXCLUDE_SILENT;
        }

        if (exclude_conflict_files && Utility.is_conflict_file (path)) {
            return CSync.ExcludedFiles.Type.CONFLICT;
        }
        return CSync.ExcludedFiles.Type.NOT_EXCLUDED;
    }


    private static string left_include_last (string arr, char c) {
        // left up to and including `c`
        return arr.left (arr.last_index_of (c, arr.size () - 2) + 1);
    }


    /***********************************************************
    On linux we used to use fnmatch with FNM_PATHNAME, but the windows function we used
    didn't have that behavior. wildcards_match_slash can be used to control which behavior
    the resulting regular_expression shall use.
    ***********************************************************/
    private static string convert_to_regexp_syntax (string exclude, bool wildcards_match_slash) {
        // Translate *, ?, [...] to their regular_expression variants.
        // The escape sequences \*, \?, \[. \\ have a special meaning,
        // the other ones have already been expanded before
        // (like "\\n" being replaced by "\n").
        //
        // string being UTF-16 makes unicode-correct escaping tricky.
        // If we escaped each UTF-16 code unit we'd end up splitting 4-byte
        // code points. To avoid problems we delegate as much work as possible to
        // QRegularExpression.escape () : It always receives as long a sequence
        // as code units as possible.
        string regular_expression;
        int i = 0;
        int chars_to_escape = 0;
        var len = exclude.size ();
        for (; i < len; ++i) {
            switch (exclude[i].unicode ()) {
            case '*':
                flush ();
                if (wildcards_match_slash) {
                    regular_expression.append (".*");
                } else {
                    regular_expression.append ("[^/]*");
                }
                break;
            case '?':
                flush ();
                if (wildcards_match_slash) {
                    regular_expression.append ('.');
                } else {
                    regular_expression.append ("[^/]");
                }
                break;
            case '[': {
                flush ();
                // Find the end of the bracket expression
                var j = i + 1;
                for (; j < len; ++j) {
                    if (exclude[j] == ']') {
                        break;
                    }
                    if (j != len - 1 && exclude[j] == '\\' && exclude[j + 1] == ']') {
                        ++j;
                    }
                }
                if (j == len) {
                    // no matching ], just insert the escaped [
                    regular_expression.append ("\\[");
                    break;
                }
                // Translate [! to [^
                string bracket_expr = exclude.mid (i, j - i + 1);
                if (bracket_expr.starts_with ("[!")) {
                    bracket_expr[1] = '^';
                }
                regular_expression.append (bracket_expr);
                i = j;
                break;
            }
            case '\\':
                flush ();
                if (i == len - 1) {
                    regular_expression.append ("\\\\");
                    break;
                }
                // '\*' . '\*', but '\z' . '\\z'
                switch (exclude[i + 1].unicode ()) {
                case '*':
                case '?':
                case '[':
                case '\\':
                    regular_expression.append (QRegularExpression.escape (exclude.mid (i + 1, 1)));
                    break;
                default:
                    chars_to_escape += 2;
                    break;
                }
                ++i;
                break;
            default:
                ++chars_to_escape;
                break;
            }
        }
        flush ();
        return regular_expression;
    }


    /***********************************************************
    FIXME: needs parameters and return values because it is no
    longer inline.
    ***********************************************************/
    private static void flush () {
        regular_expression.append (QRegularExpression.escape (exclude.mid (i - chars_to_escape, chars_to_escape)));
        chars_to_escape = 0;
    }

}
