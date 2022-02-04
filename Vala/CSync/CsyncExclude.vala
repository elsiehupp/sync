/***********************************************************
libcsync -- a library to sync a directory with another

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

//  #include <QRegularExpression>
//  #include
//  #include <functional>

enum CSYNC_EXCLUDE_TYPE {
    CSYNC_NOT_EXCLUDED   = 0,
    CSYNC_FILE_SILENTLY_EXCLUDED,
    CSYNC_FILE_EXCLUDE_AND_REMOVE,
    CSYNC_FILE_EXCLUDE_LIST,
    CSYNC_FILE_EXCLUDE_INVALID_CHAR,
    CSYNC_FILE_EXCLUDE_TRAILING_SPACE,
    CSYNC_FILE_EXCLUDE_LONG_FILENAME,
    CSYNC_FILE_EXCLUDE_HIDDEN,
    CSYNC_FILE_EXCLUDE_STAT_FAILED,
    CSYNC_FILE_EXCLUDE_CONFLICT,
    CSYNC_FILE_EXCLUDE_CANNOT_ENCODE,
    CSYNC_FILE_EXCLUDE_SERVER_BLOCKLISTED,
}


/***********************************************************
Manages file/directory exclusion.

Most commonly exclude patterns are loaded from file
add_exclude_file_path () and on_reload_exclude_files ().

Excluded files are primarily relevant for sync runs, and for
file watcher filtering.

Excluded files and ignored files are the same thing. But the
selective sync blocklist functionality is a different thing
entirely.
***********************************************************/
class ExcludedFiles : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public using Version = std.tuple<int, int, int>;

    /***********************************************************
    ***********************************************************/
    public ExcludedFiles (string local_path = "/");
    ~ExcludedFiles () override;


    /***********************************************************
    Adds a new path to a file containing exclude patterns.

    Does not load the file. Use on_reload_exclude_files () afterwards.
    ***********************************************************/
    public void add_exclude_file_path (string path);


    /***********************************************************
    Whether conflict files shall be excluded.

    Defaults to true.
    ***********************************************************/
    public void set_exclude_conflict_files (bool onoff);


    /***********************************************************
    Checks whether a file or directory should be excluded.

    @param file_path     the absolute path to the file
    @param base_path     folder path from which to apply exclude rules, ends with a /
    ***********************************************************/
    public bool is_excluded (
        const string file_path,
        const string base_path,
        bool exclude_hidden);


    /***********************************************************
    Adds an exclude pattern anchored to base path

    Primarily used in tests. Patterns added this way are preserved when
    on_reload_exclude_files () is called.
    ***********************************************************/
    public void add_manual_exclude (string expr);


    /***********************************************************
    ***********************************************************/
    public void add_manual_exclude (string expr, string base_path);


    /***********************************************************
    Removes all manually added exclude patterns.

    Primarily used in tests.
    ***********************************************************/
    public void clear_manual_excludes ();


    /***********************************************************
    Adjusts behavior of wildcards. Only used for testing.
    ***********************************************************/
    public void set_wildcards_match_slash (bool onoff);


    /***********************************************************
    Sets the client version, only used for testing.
    ***********************************************************/
    public void set_client_version (Version version);


    /***********************************************************
    @brief Check if the given path should be excluded in a traversal situation.

    It does only part of the work that full () does because it's as
    that all leading directories have been run
    before. This can be significantly faster.

    That means for 'foo/bar/file' only ('foo/bar/file', 'file')
    against the exclude patterns.

    @param Path is folder-relative, should not on_start with a /.

    Note that this only matches patterns. It does not check whether the file
    or directory pointed to is hidden (or whether it even exists).
    ***********************************************************/
    public CSYNC_EXCLUDE_TYPE traversal_pattern_match (string path, ItemType filetype);


    /***********************************************************
    Reloads the exclude patterns from the registered paths.
    ***********************************************************/
    public bool on_reload_exclude_files ();


    /***********************************************************
    Loads the exclude patterns from file the registered base paths.
    ***********************************************************/
    public void on_load_exclude_file_patterns (string base_path, GLib.File file);


    /***********************************************************
    Returns true if the version directive indicates the next line
    should be skipped.

    A version directive has the form "#!version <op> <version>"
    where <op> c
    like 2.5.

    Example:

    #!version < 2.5.0
    myexclude

    Would enable the "myexclude" pattern only for versions before 2.5.0.
    ***********************************************************/
    private bool version_directive_keep_next_line (GLib.ByteArray directive);


    /***********************************************************
    @brief Match the exclude pattern against the full path.

    @param Path is folder-relative, should not on_start with a /.

    Note that this only matches patterns. It does not check whether the file
    or directory pointed to is hidden (or whether it even exists).
    ***********************************************************/
    private CSYNC_EXCLUDE_TYPE full_pattern_match (string path, ItemType filetype);

    // Our Base_path need to end with '/'
    private class Base_path_string : string {
        public Base_path_string (string other)
            : string (std.move (other)) {
            //  Q_ASSERT (ends_with ('/'));
        }

        public Base_path_string (string other)
            : string (other) {
            //  Q_ASSERT (ends_with ('/'));
        }
    };


    /***********************************************************
    Generate optimized regular expressions for the exclude patterns anchored to base_path.

    The optimization works in two steps : First, all supported patterns are put
    into this.full_regex_file/this.full_regex_dir. These regexes
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
    case : It checks the bname part of the path against this.bname_traversal_regex
    and only runs a simplified this.full_traversal_regex on the whole path if bname
    activation for it was triggered.

    Note: The traversal matcher will return not-excluded on some paths that
    full matcher would exclude. Example: "b" is excluded. traversal ("b/c")
    returns not-excluded because "c" isn't a bname activation pattern.
    ***********************************************************/
    private void prepare (Base_path_string base_path);

    /***********************************************************
    ***********************************************************/
    private void prepare ();

    /***********************************************************
    ***********************************************************/
    private static string extract_bname_trigger (string exclude, bool wildcards_match_slash);

    /***********************************************************
    ***********************************************************/
    private 
    private string this.local_path;

    /// Files to load excludes from
    private GLib.HashMap<Base_path_string, string[]> this.exclude_files;

    /// Exclude patterns added with add_manual_exclude ()
    private GLib.HashMap<Base_path_string, string[]> this.manual_excludes;

    /// List of all active exclude patterns
    private GLib.HashMap<Base_path_string, string[]> this.all_excludes;

    /// see prepare ()
    private GLib.HashMap<Base_path_string, QRegularExpression> this.bname_traversal_regex_file;
    private GLib.HashMap<Base_path_string, QRegularExpression> this.bname_traversal_regex_dir;
    private GLib.HashMap<Base_path_string, QRegularExpression> this.full_traversal_regex_file;
    private GLib.HashMap<Base_path_string, QRegularExpression> this.full_traversal_regex_dir;
    private GLib.HashMap<Base_path_string, QRegularExpression> this.full_regex_file;
    private GLib.HashMap<Base_path_string, QRegularExpression> this.full_regex_dir;

    /***********************************************************
    ***********************************************************/
    private bool this.exclude_conflict_files = true;


    /***********************************************************
    Whether * and ? in patterns can match a /

    Unfortunately this was how matching was done on Windows so
    it continues to be enabled there.
    ***********************************************************/
    private bool this.wildcards_match_slash = false;


    /***********************************************************
    The client version. Used to evaluate version-dependent excludes,
    see version_directive_keep_next_line ().
    ***********************************************************/
    private Version this.client_version;

    /***********************************************************
    ***********************************************************/
    private friend class Test_excluded_files;
}











/***********************************************************
libcsync -- a library to sync a directory with another

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

//  #include <qglobal.h>

#ifndef this.GNU_SOURCE
const int this.GNU_SOURCE
#endif

#include "../version.h"

//  #include <QFileInfo>
//  #include <QDir>

/***********************************************************
Expands C-like escape sequences (in place)
***********************************************************/
OCSYNC_EXPORT void csync_exclude_expand_escapes (GLib.ByteArray input) {
    size_t o = 0;
    char line = input.data ();
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
                // '\*' '\?' '\[' '\\' will be processed during regex translation
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
    input.resize (Occ.Utility.convert_size_to_int (o));
}

// See http://support.microsoft.com/kb/74496 and
// https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247 (v=vs.85).aspx
// Additionally, we ignore '$Recycle.Bin', see https://github.com/owncloud/client/issues/2955
static const char win_reserved_words_3[] = {
    "CON",
    "PRN",
    "AUX",
    "NUL"
}
static const char win_reserved_words_4[] = {
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
}
static const char win_reserved_words_n[] = {
    "CLOCK$",
    "$Recycle.Bin"
}

/***********************************************************
@brief Checks if filename is considered reserved by Windows
@param filename filename
@return true if file is reserved, false otherwise
***********************************************************/
OCSYNC_EXPORT bool csync_is_windows_reserved_word (QStringRef filename) {
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
        for (char word : win_reserved_words_3) {
            if (filename.left (3).compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
                return true;
            }
        }
    }

    if (len_filename == 4 || (len_filename > 4 && filename.at (4) == '.')) {
        for (char word : win_reserved_words_4) {
            if (filename.left (4).compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
                return true;
            }
        }
    }

    for (char word : win_reserved_words_n) {
        if (filename.compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
            return true;
        }
    }

    return false;
}

static CSYNC_EXCLUDE_TYPE this.csync_excluded_common (string path, bool exclude_conflict_files) {
    /* split up the path */
    QStringRef bname (&path);
    int last_slash = path.last_index_of ('/');
    if (last_slash >= 0) {
        bname = path.mid_ref (last_slash + 1);
    }

    qsizetype blen = bname.size ();
    // 9 = strlen (".sync_.db")
    if (blen >= 9 && bname.at (0) == '.') {
        if (bname.contains (QLatin1String (".db"))) {
            if (bname.starts_with (QLatin1String (".sync_"), Qt.CaseInsensitive)  // ".sync_*.db*"
                || bname.starts_with (QLatin1String (".sync_"), Qt.CaseInsensitive) // ".sync_*.db*"
                || bname.starts_with (QLatin1String (".csync_journal.db"), Qt.CaseInsensitive)) { // ".csync_journal.db*"
                return CSYNC_FILE_SILENTLY_EXCLUDED;
            }
        }
        if (bname.starts_with (QLatin1String (".owncloudsync.log"), Qt.CaseInsensitive)) { // ".owncloudsync.log*"
            return CSYNC_FILE_SILENTLY_EXCLUDED;
        }
    }

    // check the strlen and ignore the file if its name is longer than 254 chars.
    // whenever changing this also check create_download_tmp_filename
    if (blen > 254) {
        return CSYNC_FILE_EXCLUDE_LONG_FILENAME;
    }

#ifdef this.WIN32
    // Windows cannot sync files ending in spaces (#2176). It also cannot
    // distinguish files ending in '.' from files without an ending,
    // as '.' is a separator that is not stored internally, so let's
    // not allow to sync those to avoid file loss/ambiguities (#416)
    if (blen > 1) {
        if (bname.at (blen - 1) == ' ') {
            return CSYNC_FILE_EXCLUDE_TRAILING_SPACE;
        } else if (bname.at (blen - 1) == '.') {
            return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
        }
    }

    if (csync_is_windows_reserved_word (bname)) {
        return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
    }

    // Filter out characters not allowed in a filename on windows
    for (var p : path) {
        const ushort c = p.unicode ();
        if (c < 32) {
            return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
        }
        switch (c) {
        case '\\':
        case ':':
        case '?':
        case '*':
        case '"':
        case '>':
        case '<':
        case '|':
            return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
        default:
            break;
        }
    }
#endif

    /* Do not sync desktop.ini files anywhere in the tree. */
    const var desktop_ini_file = QStringLiteral ("desktop.ini");
    if (blen == static_cast<qsizetype> (desktop_ini_file.length ()) && bname.compare (desktop_ini_file, Qt.CaseInsensitive) == 0) {
        return CSYNC_FILE_SILENTLY_EXCLUDED;
    }

    if (exclude_conflict_files && Occ.Utility.is_conflict_file (path)) {
        return CSYNC_FILE_EXCLUDE_CONFLICT;
    }
    return CSYNC_NOT_EXCLUDED;
}

static string left_include_last (string arr, char c) {
    // left up to and including `c`
    return arr.left (arr.last_index_of (c, arr.size () - 2) + 1);
}

using namespace Occ;

ExcludedFiles.ExcludedFiles (string local_path)
    : this.local_path (local_path)
    this.client_version (MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR, MIRALL_VERSION_PATCH) {
    //  Q_ASSERT (this.local_path.ends_with (QStringLiteral ("/")));
    // Windows used to use Path_match_spec which allows foo to match abc/deffoo.
    this.wildcards_match_slash = Utility.is_windows ();

    // We're in a detached exclude probably coming from a partial sync or test
    if (this.local_path.is_empty ())
        return;
}

ExcludedFiles.~ExcludedFiles () = default;

void ExcludedFiles.add_exclude_file_path (string path) {
    const QFileInfo exclude_file_info (path);
    const var filename = exclude_file_info.filename ();
    const var base_path = filename.compare (QStringLiteral ("sync-exclude.lst"), Qt.CaseInsensitive) == 0
                                                                    ? this.local_path
                                                                    : left_include_last (path, '/');
    var exclude_files_local_path = this.exclude_files[base_path];
    if (std.find (exclude_files_local_path.cbegin (), exclude_files_local_path.cend (), path) == exclude_files_local_path.cend ()) {
        exclude_files_local_path.append (path);
    }
}

void ExcludedFiles.set_exclude_conflict_files (bool onoff) {
    this.exclude_conflict_files = onoff;
}

void ExcludedFiles.add_manual_exclude (string expr) {
    add_manual_exclude (expr, this.local_path);
}

void ExcludedFiles.add_manual_exclude (string expr, string base_path) {
    //  Q_ASSERT (base_path.ends_with ('/'));

    var key = base_path;
    this.manual_excludes[key].append (expr);
    this.all_excludes[key].append (expr);
    prepare (key);
}

void ExcludedFiles.clear_manual_excludes () {
    this.manual_excludes.clear ();
    on_reload_exclude_files ();
}

void ExcludedFiles.set_wildcards_match_slash (bool onoff) {
    this.wildcards_match_slash = onoff;
    prepare ();
}

void ExcludedFiles.set_client_version (ExcludedFiles.Version version) {
    this.client_version = version;
}

void ExcludedFiles.on_load_exclude_file_patterns (string base_path, GLib.File file) {
    string[] patterns;
    while (!file.at_end ()) {
        GLib.ByteArray line = file.read_line ().trimmed ();
        if (line.starts_with ("#!version")) {
            if (!version_directive_keep_next_line (line))
                file.read_line ();
        }
        if (line.is_empty () || line.starts_with ('#'))
            continue;
        csync_exclude_expand_escapes (line);
        patterns.append (string.from_utf8 (line));
    }
    this.all_excludes[base_path].append (patterns);

    // nothing to prepare if the user decided to not exclude anything
    if (!this.all_excludes.value (base_path).is_empty ()){
        prepare (base_path);
    }
}

bool ExcludedFiles.on_reload_exclude_files () {
    this.all_excludes.clear ();
    // clear all regex
    this.bname_traversal_regex_file.clear ();
    this.bname_traversal_regex_dir.clear ();
    this.full_traversal_regex_file.clear ();
    this.full_traversal_regex_dir.clear ();
    this.full_regex_file.clear ();
    this.full_regex_dir.clear ();

    bool on_success = true;
    const var keys = this.exclude_files.keys ();
    for (var& base_path : keys) {
        for (var exclude_file : this.exclude_files.value (base_path)) {
            GLib.File file = new GLib.File (exclude_file);
            if (file.exists () && file.open (QIODevice.ReadOnly)) {
                on_load_exclude_file_patterns (base_path, file);
            } else {
                on_success = false;
                q_warning () << "System exclude list file could not be opened:" << exclude_file;
            }
        }
    }

    var end_manual = this.manual_excludes.cend ();
    for (var kv = this.manual_excludes.cbegin (); kv != end_manual; ++kv) {
        this.all_excludes[kv.key ()].append (kv.value ());
        prepare (kv.key ());
    }

    return on_success;
}

bool ExcludedFiles.version_directive_keep_next_line (GLib.ByteArray directive) {
    if (!directive.starts_with ("#!version"))
        return true;
    QByte_array_list args = directive.split (' ');
    if (args.size () != 3)
        return true;
    GLib.ByteArray op = args[1];
    QByte_array_list arg_versions = args[2].split ('.');
    if (arg_versions.size () != 3)
        return true;

    var arg_version = std.make_tuple (arg_versions[0].to_int (), arg_versions[1].to_int (), arg_versions[2].to_int ());
    if (op == "<=")
        return this.client_version <= arg_version;
    if (op == "<")
        return this.client_version < arg_version;
    if (op == ">")
        return this.client_version > arg_version;
    if (op == ">=")
        return this.client_version >= arg_version;
    if (op == "==")
        return this.client_version == arg_version;
    return true;
}

bool ExcludedFiles.is_excluded (
    const string file_path,
    const string base_path,
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
            QFileInfo fi (path);
            if (fi.filename () != QStringLiteral (".sync-exclude.lst")
                && (fi.is_hidden () || fi.filename ().starts_with ('.'))) {
                return true;
            }

            // Get the parent path
            path = fi.absolute_path ();
        }
    }

    QFileInfo fi (file_path);
    ItemType type = ItemTypeFile;
    if (fi.is_dir ()) {
        type = ItemTypeDirectory;
    }

    string relative_path = file_path.mid (base_path.size ());
    if (relative_path.ends_with ('/')) {
        relative_path.chop (1);
    }

    return full_pattern_match (relative_path, type) != CSYNC_NOT_EXCLUDED;
}

CSYNC_EXCLUDE_TYPE ExcludedFiles.traversal_pattern_match (string path, ItemType filetype) {
    var match = this.csync_excluded_common (path, this.exclude_conflict_files);
    if (match != CSYNC_NOT_EXCLUDED)
        return match;
    if (this.all_excludes.is_empty ())
        return CSYNC_NOT_EXCLUDED;

    // Directories are guaranteed to be visited before their files
    if (filetype == ItemTypeDirectory) {
        const var base_path = string (this.local_path + path + '/');
        const string absolute_path = base_path + QStringLiteral (".sync-exclude.lst");
        QFileInfo exclude_file_info (absolute_path);

        if (exclude_file_info.is_readable ()) {
            add_exclude_file_path (absolute_path);
            on_reload_exclude_files ();
        } else {
            q_warning () << "System exclude list file could not be read:" << absolute_path;
        }
    }

    // Check the bname part of the path to see whether the full
    // regex should be run.
    QStringRef bname_str (&path);
    int last_slash = path.last_index_of ('/');
    if (last_slash >= 0) {
        bname_str = path.mid_ref (last_slash + 1);
    }

    string base_path (this.local_path + path);
    while (base_path.size () > this.local_path.size ()) {
        base_path = left_include_last (base_path, '/');
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && this.bname_traversal_regex_dir.contains (base_path)) {
            m = this.bname_traversal_regex_dir[base_path].match (bname_str);
        } else if (filetype == ItemTypeFile
            && this.bname_traversal_regex_file.contains (base_path)) {
            m = this.bname_traversal_regex_file[base_path].match (bname_str);
        } else {
            continue;
        }

        if (!m.has_match ())
            return CSYNC_NOT_EXCLUDED;
        if (m.captured_start (QStringLiteral ("exclude")) != -1) {
            return CSYNC_FILE_EXCLUDE_LIST;
        } else if (m.captured_start (QStringLiteral ("excluderemove")) != -1) {
            return CSYNC_FILE_EXCLUDE_AND_REMOVE;
        }
    }

    // third capture : full path matching is triggered
    base_path = this.local_path + path;
    while (base_path.size () > this.local_path.size ()) {
        base_path = left_include_last (base_path, '/');
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && this.full_traversal_regex_dir.contains (base_path)) {
            m = this.full_traversal_regex_dir[base_path].match (path);
        } else if (filetype == ItemTypeFile
            && this.full_traversal_regex_file.contains (base_path)) {
            m = this.full_traversal_regex_file[base_path].match (path);
        } else {
            continue;
        }

        if (m.has_match ()) {
            if (m.captured_start (QStringLiteral ("exclude")) != -1) {
                return CSYNC_FILE_EXCLUDE_LIST;
            } else if (m.captured_start (QStringLiteral ("excluderemove")) != -1) {
                return CSYNC_FILE_EXCLUDE_AND_REMOVE;
            }
        }
    }
    return CSYNC_NOT_EXCLUDED;
}

CSYNC_EXCLUDE_TYPE ExcludedFiles.full_pattern_match (string p, ItemType filetype) {
    var match = this.csync_excluded_common (p, this.exclude_conflict_files);
    if (match != CSYNC_NOT_EXCLUDED)
        return match;
    if (this.all_excludes.is_empty ())
        return CSYNC_NOT_EXCLUDED;

    // `path` seems to always be relative to `this.local_path`, the tests however have not been
    // written that way... this makes the tests happy for now. TODO Fix the tests at some point
    string path = p;
    if (path.starts_with (this.local_path))
        path = path.mid (this.local_path.size ());

    string base_path (this.local_path + path);
    while (base_path.size () > this.local_path.size ()) {
        base_path = left_include_last (base_path, '/');
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && this.full_regex_dir.contains (base_path)) {
            m = this.full_regex_dir[base_path].match (p);
        } else if (filetype == ItemTypeFile
            && this.full_regex_file.contains (base_path)) {
            m = this.full_regex_file[base_path].match (p);
        } else {
            continue;
        }

        if (m.has_match ()) {
            if (m.captured_start (QStringLiteral ("exclude")) != -1) {
                return CSYNC_FILE_EXCLUDE_LIST;
            } else if (m.captured_start (QStringLiteral ("excluderemove")) != -1) {
                return CSYNC_FILE_EXCLUDE_AND_REMOVE;
            }
        }
    }

    return CSYNC_NOT_EXCLUDED;
}

/***********************************************************
On linux we used to use fnmatch with FNM_PATHNAME, but the windows function we used
didn't have that behavior. wildcards_match_slash can be used to control which behavior
the resulting regex shall use.
***********************************************************/
string ExcludedFiles.convert_to_regexp_syntax (string exclude, bool wildcards_match_slash) {
    // Translate *, ?, [...] to their regex variants.
    // The escape sequences \*, \?, \[. \\ have a special meaning,
    // the other ones have already been expanded before
    // (like "\\n" being replaced by "\n").
    //
    // string being UTF-16 makes unicode-correct escaping tricky.
    // If we escaped each UTF-16 code unit we'd end up splitting 4-byte
    // code points. To avoid problems we delegate as much work as possible to
    // QRegularExpression.escape () : It always receives as long a sequence
    // as code units as possible.
    string regex;
    int i = 0;
    int chars_to_escape = 0;
    var flush = [&] () {
        regex.append (QRegularExpression.escape (exclude.mid (i - chars_to_escape, chars_to_escape)));
        chars_to_escape = 0;
    };
    var len = exclude.size ();
    for (; i < len; ++i) {
        switch (exclude[i].unicode ()) {
        case '*':
            flush ();
            if (wildcards_match_slash) {
                regex.append (QLatin1String (".*"));
            } else {
                regex.append (QLatin1String ("[^/]*"));
            }
            break;
        case '?':
            flush ();
            if (wildcards_match_slash) {
                regex.append ('.');
            } else {
                regex.append (QStringLiteral ("[^/]"));
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
                regex.append (QStringLiteral ("\\["));
                break;
            }
            // Translate [! to [^
            string bracket_expr = exclude.mid (i, j - i + 1);
            if (bracket_expr.starts_with ("[!")) {
                bracket_expr[1] = '^';
            }
            regex.append (bracket_expr);
            i = j;
            break;
        }
        case '\\':
            flush ();
            if (i == len - 1) {
                regex.append (QStringLiteral ("\\\\"));
                break;
            }
            // '\*' . '\*', but '\z' . '\\z'
            switch (exclude[i + 1].unicode ()) {
            case '*':
            case '?':
            case '[':
            case '\\':
                regex.append (QRegularExpression.escape (exclude.mid (i + 1, 1)));
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
    return regex;
}

string ExcludedFiles.extract_bname_trigger (string exclude, bool wildcards_match_slash) {
    // We can definitely drop everything to the left of a / - that will never match
    // any bname.
    string pattern = exclude.mid (exclude.last_index_of ('/') + 1);

    // Easy case, nothing else can match a slash, so that's it.
    if (!wildcards_match_slash)
        return pattern;

    // Otherwise it's more complicated. Examples:
    // - "foo*bar" can match "foo_x/Xbar", pattern is "*bar"
    // - "foo*bar*" can match "foo_x/Xbar_x", pattern is "*bar*"
    // - "foo?bar" can match "foo/bar" but also "foo_xbar", pattern is "*bar"

    var is_wildcard = [] (char c) {
        return c == '*' || c == '?';
    };

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

void ExcludedFiles.prepare () {
    // clear all regex
    this.bname_traversal_regex_file.clear ();
    this.bname_traversal_regex_dir.clear ();
    this.full_traversal_regex_file.clear ();
    this.full_traversal_regex_dir.clear ();
    this.full_regex_file.clear ();
    this.full_regex_dir.clear ();

    const var keys = this.all_excludes.keys ();
    for (var const & base_path : keys)
        prepare (base_path);
}

void ExcludedFiles.prepare (Base_path_string & base_path) {
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
    //   in the pattern strings saying "Dir", the others go into "File_dir"
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

    var regex_append = [] (string file_dir_pattern, string dir_pattern, string append_me, bool dir_only) {
        string pattern = dir_only ? dir_pattern : file_dir_pattern;
        if (!pattern.is_empty ()) {
            pattern.append ('|');
        }
        pattern.append (append_me);
    };

    for (var exclude : this.all_excludes.value (base_path)) {
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

    // The empty pattern would match everything - change it to match-nothing
    var empty_match_nothing = [] (string pattern) {
        if (pattern.is_empty ())
            pattern = QStringLiteral ("a^");
    };
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

    // The bname regex is applied to the bname only, so it must be
    // anchored in the beginning and in the end. It has the structure:
    // (exclude)| (excluderemove)| (bname triggers).
    // If the third group matches, the full_activated_regex needs to be applied
    // to the full path.
    this.bname_traversal_regex_file[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1)$|"
                       "^ (?P<excluderemove>%2)$|"
                       "^ (?P<trigger>%3)$")
            .arg (bname_file_dir_keep, bname_file_dir_remove, bname_trigger_file_dir));
    this.bname_traversal_regex_dir[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1|%2)$|"
                       "^ (?P<excluderemove>%3|%4)$|"
                       "^ (?P<trigger>%5|%6)$")
            .arg (bname_file_dir_keep, bname_dir_keep, bname_file_dir_remove, bname_dir_remove, bname_trigger_file_dir, bname_trigger_dir));

    // The full traveral regex is applied to the full path if the trigger capture of
    // the bname regex matches. Its basic form is (exclude)| (excluderemove)".
    // This pattern can be much simpler than full_regex since we can assume a traversal
    // situation and doesn't need to look for bname patterns in parent paths.
    this.full_traversal_regex_file[base_path].set_pattern (
        // Full patterns are anchored to the beginning
        QStringLiteral ("^ (?P<exclude>%1) (?:$|/)"
                       "|"
                       "^ (?P<excluderemove>%2) (?:$|/)")
            .arg (full_file_dir_keep, full_file_dir_remove));
    this.full_traversal_regex_dir[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1|%2) (?:$|/)"
                       "|"
                       "^ (?P<excluderemove>%3|%4) (?:$|/)")
            .arg (full_file_dir_keep, full_dir_keep, full_file_dir_remove, full_dir_remove));

    // The full regex is applied to the full path and incorporates both bname and
    // full-path patterns. It has the form " (exclude)| (excluderemove)".
    this.full_regex_file[base_path].set_pattern (
        QStringLiteral (" (?P<exclude>"
                       // Full patterns are anchored to the beginning
                       "^ (?:%1) (?:$|/)|"
                       // Simple bname patterns can be any path component
                       " (?:^|/) (?:%2) (?:$|/)|"
                       // When checking a file for exclusion we must check all parent paths
                       // against the dir-only patterns as well.
                       " (?:^|/) (?:%3)/)"
                       "|"
                       " (?P<excluderemove>"
                       "^ (?:%4) (?:$|/)|"
                       " (?:^|/) (?:%5) (?:$|/)|"
                       " (?:^|/) (?:%6)/)")
            .arg (full_file_dir_keep, bname_file_dir_keep, bname_dir_keep, full_file_dir_remove, bname_file_dir_remove, bname_dir_remove));
    this.full_regex_dir[base_path].set_pattern (
        QStringLiteral (" (?P<exclude>"
                       "^ (?:%1|%2) (?:$|/)|"
                       " (?:^|/) (?:%3|%4) (?:$|/))"
                       "|"
                       " (?P<excluderemove>"
                       "^ (?:%5|%6) (?:$|/)|"
                       " (?:^|/) (?:%7|%8) (?:$|/))")
            .arg (full_file_dir_keep, full_dir_keep, bname_file_dir_keep, bname_dir_keep, full_file_dir_remove, full_dir_remove, bname_file_dir_remove, bname_dir_remove));

    QRegularExpression.Pattern_options pattern_options = QRegularExpression.No_pattern_option;
    if (Occ.Utility.fs_case_preserving ())
        pattern_options |= QRegularExpression.Case_insensitive_option;
    this.bname_traversal_regex_file[base_path].set_pattern_options (pattern_options);
    this.bname_traversal_regex_file[base_path].optimize ();
    this.bname_traversal_regex_dir[base_path].set_pattern_options (pattern_options);
    this.bname_traversal_regex_dir[base_path].optimize ();
    this.full_traversal_regex_file[base_path].set_pattern_options (pattern_options);
    this.full_traversal_regex_file[base_path].optimize ();
    this.full_traversal_regex_dir[base_path].set_pattern_options (pattern_options);
    this.full_traversal_regex_dir[base_path].optimize ();
    this.full_regex_file[base_path].set_pattern_options (pattern_options);
    this.full_regex_file[base_path].optimize ();
    this.full_regex_dir[base_path].set_pattern_options (pattern_options);
    this.full_regex_dir[base_path].optimize ();
}
