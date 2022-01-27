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

// #include <QSet>
// #include <string>
// #include <QRegularExpression>

// #include <functional>

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
    CSYNC_FILE_EXCLUDE_SERVER_BLACKLISTED,
};


/***********************************************************
Manages file/directory exclusion.

Most commonly exclude patterns are loaded from file
add_exclude_file_path () and on_reload_exclude_files ().

Excluded files are primarily relevant for sync runs, and for
file watcher filtering.

Excluded files and ignored files are the same thing. But the
selective sync blacklist functionality is a different thing
entirely.
***********************************************************/
class ExcludedFiles : GLib.Object {

    public using Version = std.tuple<int, int, int>;

    public ExcludedFiles (string local_path = QStringLiteral ("/"));
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
    public void on_load_exclude_file_patterns (string base_path, QFile &file);


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
    private bool version_directive_keep_next_line (GLib.ByteArray &directive);

    /***********************************************************
    @brief Match the exclude pattern against the full path.

    @param Path is folder-relative, should not on_start with a /.

    Note that this only matches patterns. It does not check whether the file
    or directory pointed to is hidden (or whether it even exists).
    ***********************************************************/
    private CSYNC_EXCLUDE_TYPE full_pattern_match (string path, ItemType filetype);

    // Our Base_path need to end with '/'
    private class Base_path_string : string {
        public Base_path_string (string &other)
            : string (std.move (other)) {
            Q_ASSERT (ends_with (QLatin1Char ('/')));
        }

        public Base_path_string (string other)
            : string (other) {
            Q_ASSERT (ends_with (QLatin1Char ('/')));
        }
    };

    /***********************************************************
    Generate optimized regular expressions for the exclude patterns anchored to base_path.

    The optimization works in two steps : First, all supported patterns are put
    into _full_regex_file/_full_regex_dir. These regexes
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
    case : It checks the bname part of the path against _bname_traversal_regex
    and only runs a simplified _full_traversal_regex on the whole path if bname
    activation for it was triggered.

    Note : The traversal matcher will return not-excluded on some paths that
    full matcher would exclude. Example: "b" is excluded. traversal ("b/c")
    returns not-excluded because "c" isn't a bname activation pattern.
    ***********************************************************/
    private void prepare (Base_path_string &base_path);

    private void prepare ();

    private static string extract_bname_trigger (string exclude, bool wildcards_match_slash);
    private static string convert_to_regexp_syntax (string exclude, bool wildcards_match_slash);

    private string _local_path;

    /// Files to load excludes from
    private QMap<Base_path_string, string[]> _exclude_files;

    /// Exclude patterns added with add_manual_exclude ()
    private QMap<Base_path_string, string[]> _manual_excludes;

    /// List of all active exclude patterns
    private QMap<Base_path_string, string[]> _all_excludes;

    /// see prepare ()
    private QMap<Base_path_string, QRegularExpression> _bname_traversal_regex_file;
    private QMap<Base_path_string, QRegularExpression> _bname_traversal_regex_dir;
    private QMap<Base_path_string, QRegularExpression> _full_traversal_regex_file;
    private QMap<Base_path_string, QRegularExpression> _full_traversal_regex_dir;
    private QMap<Base_path_string, QRegularExpression> _full_regex_file;
    private QMap<Base_path_string, QRegularExpression> _full_regex_dir;

    private bool _exclude_conflict_files = true;

    /***********************************************************
    Whether * and ? in patterns can match a /

    Unfortunately this was how matching was done on Windows so
    it continues to be enabled there.
    ***********************************************************/
    private bool _wildcards_match_slash = false;

    /***********************************************************
    The client version. Used to evaluate version-dependent excludes,
    see version_directive_keep_next_line ().
    ***********************************************************/
    private Version _client_version;

    private friend class Test_excluded_files;
};











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

// #include <qglobal.h>

#ifndef _GNU_SOURCE
const int _GNU_SOURCE
#endif

#include "../version.h"

// #include <string>
// #include <QFileInfo>
// #include <QDir>

/***********************************************************
Expands C-like escape sequences (in place)
***********************************************************/
OCSYNC_EXPORT void csync_exclude_expand_escapes (GLib.ByteArray &input) {
    size_t o = 0;
    char *line = input.data ();
    auto len = input.size ();
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
static const char *win_reserved_words_3[] = {
    "CON",
    "PRN",
    "AUX",
    "NUL"
};
static const char *win_reserved_words_4[] = {
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
static const char *win_reserved_words_n[] = {
    "CLOCK$",
    "$Recycle.Bin"
};

/***********************************************************
@brief Checks if filename is considered reserved by Windows
@param file_name filename
@return true if file is reserved, false otherwise
***********************************************************/
OCSYNC_EXPORT bool csync_is_windows_reserved_word (QStringRef &filename) {
    size_t len_filename = filename.size ();

    // Drive letters
    if (len_filename == 2 && filename.at (1) == QLatin1Char (':')) {
        if (filename.at (0) >= QLatin1Char ('a') && filename.at (0) <= QLatin1Char ('z')) {
            return true;
        }
        if (filename.at (0) >= QLatin1Char ('A') && filename.at (0) <= QLatin1Char ('Z')) {
            return true;
        }
    }

    if (len_filename == 3 || (len_filename > 3 && filename.at (3) == QLatin1Char ('.'))) {
        for (char *word : win_reserved_words_3) {
            if (filename.left (3).compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
                return true;
            }
        }
    }

    if (len_filename == 4 || (len_filename > 4 && filename.at (4) == QLatin1Char ('.'))) {
        for (char *word : win_reserved_words_4) {
            if (filename.left (4).compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
                return true;
            }
        }
    }

    for (char *word : win_reserved_words_n) {
        if (filename.compare (QLatin1String (word), Qt.CaseInsensitive) == 0) {
            return true;
        }
    }

    return false;
}

static CSYNC_EXCLUDE_TYPE _csync_excluded_common (string path, bool exclude_conflict_files) {
    /* split up the path */
    QStringRef bname (&path);
    int last_slash = path.last_index_of (QLatin1Char ('/'));
    if (last_slash >= 0) {
        bname = path.mid_ref (last_slash + 1);
    }

    qsizetype blen = bname.size ();
    // 9 = strlen (".sync_.db")
    if (blen >= 9 && bname.at (0) == QLatin1Char ('.')) {
        if (bname.contains (QLatin1String (".db"))) {
            if (bname.starts_with (QLatin1String ("._sync_"), Qt.CaseInsensitive)  // "._sync_*.db*"
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
    // whenever changing this also check create_download_tmp_file_name
    if (blen > 254) {
        return CSYNC_FILE_EXCLUDE_LONG_FILENAME;
    }

#ifdef _WIN32
    // Windows cannot sync files ending in spaces (#2176). It also cannot
    // distinguish files ending in '.' from files without an ending,
    // as '.' is a separator that is not stored internally, so let's
    // not allow to sync those to avoid file loss/ambiguities (#416)
    if (blen > 1) {
        if (bname.at (blen - 1) == QLatin1Char (' ')) {
            return CSYNC_FILE_EXCLUDE_TRAILING_SPACE;
        } else if (bname.at (blen - 1) == QLatin1Char ('.')) {
            return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
        }
    }

    if (csync_is_windows_reserved_word (bname)) {
        return CSYNC_FILE_EXCLUDE_INVALID_CHAR;
    }

    // Filter out characters not allowed in a filename on windows
    for (auto p : path) {
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
    const auto desktop_ini_file = QStringLiteral ("desktop.ini");
    if (blen == static_cast<qsizetype> (desktop_ini_file.length ()) && bname.compare (desktop_ini_file, Qt.CaseInsensitive) == 0) {
        return CSYNC_FILE_SILENTLY_EXCLUDED;
    }

    if (exclude_conflict_files && Occ.Utility.is_conflict_file (path)) {
        return CSYNC_FILE_EXCLUDE_CONFLICT;
    }
    return CSYNC_NOT_EXCLUDED;
}

static string left_include_last (string arr, QChar &c) {
    // left up to and including `c`
    return arr.left (arr.last_index_of (c, arr.size () - 2) + 1);
}

using namespace Occ;

ExcludedFiles.ExcludedFiles (string local_path)
    : _local_path (local_path)
    , _client_version (MIRALL_VERSION_MAJOR, MIRALL_VERSION_MINOR, MIRALL_VERSION_PATCH) {
    Q_ASSERT (_local_path.ends_with (QStringLiteral ("/")));
    // Windows used to use Path_match_spec which allows *foo to match abc/deffoo.
    _wildcards_match_slash = Utility.is_windows ();

    // We're in a detached exclude probably coming from a partial sync or test
    if (_local_path.is_empty ())
        return;
}

ExcludedFiles.~ExcludedFiles () = default;

void ExcludedFiles.add_exclude_file_path (string path) {
    const QFileInfo exclude_file_info (path);
    const auto file_name = exclude_file_info.file_name ();
    const auto base_path = file_name.compare (QStringLiteral ("sync-exclude.lst"), Qt.CaseInsensitive) == 0
                                                                    ? _local_path
                                                                    : left_include_last (path, QLatin1Char ('/'));
    auto &exclude_files_local_path = _exclude_files[base_path];
    if (std.find (exclude_files_local_path.cbegin (), exclude_files_local_path.cend (), path) == exclude_files_local_path.cend ()) {
        exclude_files_local_path.append (path);
    }
}

void ExcludedFiles.set_exclude_conflict_files (bool onoff) {
    _exclude_conflict_files = onoff;
}

void ExcludedFiles.add_manual_exclude (string expr) {
    add_manual_exclude (expr, _local_path);
}

void ExcludedFiles.add_manual_exclude (string expr, string base_path) {
    Q_ASSERT (base_path.ends_with (QLatin1Char ('/')));

    auto key = base_path;
    _manual_excludes[key].append (expr);
    _all_excludes[key].append (expr);
    prepare (key);
}

void ExcludedFiles.clear_manual_excludes () {
    _manual_excludes.clear ();
    on_reload_exclude_files ();
}

void ExcludedFiles.set_wildcards_match_slash (bool onoff) {
    _wildcards_match_slash = onoff;
    prepare ();
}

void ExcludedFiles.set_client_version (ExcludedFiles.Version version) {
    _client_version = version;
}

void ExcludedFiles.on_load_exclude_file_patterns (string base_path, QFile &file) {
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
    _all_excludes[base_path].append (patterns);

    // nothing to prepare if the user decided to not exclude anything
    if (!_all_excludes.value (base_path).is_empty ()){
        prepare (base_path);
    }
}

bool ExcludedFiles.on_reload_exclude_files () {
    _all_excludes.clear ();
    // clear all regex
    _bname_traversal_regex_file.clear ();
    _bname_traversal_regex_dir.clear ();
    _full_traversal_regex_file.clear ();
    _full_traversal_regex_dir.clear ();
    _full_regex_file.clear ();
    _full_regex_dir.clear ();

    bool on_success = true;
    const auto keys = _exclude_files.keys ();
    for (auto& base_path : keys) {
        for (auto &exclude_file : _exclude_files.value (base_path)) {
            QFile file (exclude_file);
            if (file.exists () && file.open (QIODevice.ReadOnly)) {
                on_load_exclude_file_patterns (base_path, file);
            } else {
                on_success = false;
                q_warning () << "System exclude list file could not be opened:" << exclude_file;
            }
        }
    }

    auto end_manual = _manual_excludes.cend ();
    for (auto kv = _manual_excludes.cbegin (); kv != end_manual; ++kv) {
        _all_excludes[kv.key ()].append (kv.value ());
        prepare (kv.key ());
    }

    return on_success;
}

bool ExcludedFiles.version_directive_keep_next_line (GLib.ByteArray &directive) {
    if (!directive.starts_with ("#!version"))
        return true;
    QByte_array_list args = directive.split (' ');
    if (args.size () != 3)
        return true;
    GLib.ByteArray op = args[1];
    QByte_array_list arg_versions = args[2].split ('.');
    if (arg_versions.size () != 3)
        return true;

    auto arg_version = std.make_tuple (arg_versions[0].to_int (), arg_versions[1].to_int (), arg_versions[2].to_int ());
    if (op == "<=")
        return _client_version <= arg_version;
    if (op == "<")
        return _client_version < arg_version;
    if (op == ">")
        return _client_version > arg_version;
    if (op == ">=")
        return _client_version >= arg_version;
    if (op == "==")
        return _client_version == arg_version;
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
        // Check all path subcomponents, but to *not* check the base path:
        // We do want to be able to sync with a hidden folder as the target.
        while (path.size () > base_path.size ()) {
            QFileInfo fi (path);
            if (fi.file_name () != QStringLiteral (".sync-exclude.lst")
                && (fi.is_hidden () || fi.file_name ().starts_with (QLatin1Char ('.')))) {
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
    if (relative_path.ends_with (QLatin1Char ('/'))) {
        relative_path.chop (1);
    }

    return full_pattern_match (relative_path, type) != CSYNC_NOT_EXCLUDED;
}

CSYNC_EXCLUDE_TYPE ExcludedFiles.traversal_pattern_match (string path, ItemType filetype) {
    auto match = _csync_excluded_common (path, _exclude_conflict_files);
    if (match != CSYNC_NOT_EXCLUDED)
        return match;
    if (_all_excludes.is_empty ())
        return CSYNC_NOT_EXCLUDED;

    // Directories are guaranteed to be visited before their files
    if (filetype == ItemTypeDirectory) {
        const auto base_path = string (_local_path + path + QLatin1Char ('/'));
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
    int last_slash = path.last_index_of (QLatin1Char ('/'));
    if (last_slash >= 0) {
        bname_str = path.mid_ref (last_slash + 1);
    }

    string base_path (_local_path + path);
    while (base_path.size () > _local_path.size ()) {
        base_path = left_include_last (base_path, QLatin1Char ('/'));
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && _bname_traversal_regex_dir.contains (base_path)) {
            m = _bname_traversal_regex_dir[base_path].match (bname_str);
        } else if (filetype == ItemTypeFile
            && _bname_traversal_regex_file.contains (base_path)) {
            m = _bname_traversal_regex_file[base_path].match (bname_str);
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
    base_path = _local_path + path;
    while (base_path.size () > _local_path.size ()) {
        base_path = left_include_last (base_path, QLatin1Char ('/'));
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && _full_traversal_regex_dir.contains (base_path)) {
            m = _full_traversal_regex_dir[base_path].match (path);
        } else if (filetype == ItemTypeFile
            && _full_traversal_regex_file.contains (base_path)) {
            m = _full_traversal_regex_file[base_path].match (path);
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
    auto match = _csync_excluded_common (p, _exclude_conflict_files);
    if (match != CSYNC_NOT_EXCLUDED)
        return match;
    if (_all_excludes.is_empty ())
        return CSYNC_NOT_EXCLUDED;

    // `path` seems to always be relative to `_local_path`, the tests however have not been
    // written that way... this makes the tests happy for now. TODO Fix the tests at some point
    string path = p;
    if (path.starts_with (_local_path))
        path = path.mid (_local_path.size ());

    string base_path (_local_path + path);
    while (base_path.size () > _local_path.size ()) {
        base_path = left_include_last (base_path, QLatin1Char ('/'));
        QRegular_expression_match m;
        if (filetype == ItemTypeDirectory
            && _full_regex_dir.contains (base_path)) {
            m = _full_regex_dir[base_path].match (p);
        } else if (filetype == ItemTypeFile
            && _full_regex_file.contains (base_path)) {
            m = _full_regex_file[base_path].match (p);
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
    auto flush = [&] () {
        regex.append (QRegularExpression.escape (exclude.mid (i - chars_to_escape, chars_to_escape)));
        chars_to_escape = 0;
    };
    auto len = exclude.size ();
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
                regex.append (QLatin1Char ('.'));
            } else {
                regex.append (QStringLiteral ("[^/]"));
            }
            break;
        case '[' : {
            flush ();
            // Find the end of the bracket expression
            auto j = i + 1;
            for (; j < len; ++j) {
                if (exclude[j] == QLatin1Char (']'))
                    break;
                if (j != len - 1 && exclude[j] == QLatin1Char ('\\') && exclude[j + 1] == QLatin1Char (']'))
                    ++j;
            }
            if (j == len) {
                // no matching ], just insert the escaped [
                regex.append (QStringLiteral ("\\["));
                break;
            }
            // Translate [! to [^
            string bracket_expr = exclude.mid (i, j - i + 1);
            if (bracket_expr.starts_with (QLatin1String ("[!")))
                bracket_expr[1] = QLatin1Char ('^');
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
    string pattern = exclude.mid (exclude.last_index_of (QLatin1Char ('/')) + 1);

    // Easy case, nothing else can match a slash, so that's it.
    if (!wildcards_match_slash)
        return pattern;

    // Otherwise it's more complicated. Examples:
    // - "foo*bar" can match "foo_x/Xbar", pattern is "*bar"
    // - "foo*bar*" can match "foo_x/Xbar_x", pattern is "*bar*"
    // - "foo?bar" can match "foo/bar" but also "foo_xbar", pattern is "*bar"

    auto is_wildcard = [] (QChar c) {
        return c == QLatin1Char ('*') || c == QLatin1Char ('?');
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
    if (i >= 0)
        pattern.prepend (QLatin1Char ('*'));

    return pattern;
}

void ExcludedFiles.prepare () {
    // clear all regex
    _bname_traversal_regex_file.clear ();
    _bname_traversal_regex_dir.clear ();
    _full_traversal_regex_file.clear ();
    _full_traversal_regex_dir.clear ();
    _full_regex_file.clear ();
    _full_regex_dir.clear ();

    const auto keys = _all_excludes.keys ();
    for (auto const & base_path : keys)
        prepare (base_path);
}

void ExcludedFiles.prepare (Base_path_string & base_path) {
    Q_ASSERT (_all_excludes.contains (base_path));

    // Build regular expressions for the different cases.
    //
    // To compose the _bname_traversal_regex, _full_traversal_regex and _full_regex
    // patterns we collect several subgroups of patterns here.
    //
    // * The "full" group will contain all patterns that contain a non-trailing
    //   slash. They only make sense in the full_regex and full_traversal_regex.
    // * The "bname" group contains all patterns without a non-trailing slash.
    //   These need separate handling in the _full_regex (slash-containing
    //   patterns must be anchored to the front, these don't need it)
    // * The "bname_trigger" group contains the bname part of all patterns in the
    //   "full" group. These and the "bname" group become _bname_traversal_regex.
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

    auto regex_append = [] (string file_dir_pattern, string dir_pattern, string append_me, bool dir_only) {
        string pattern = dir_only ? dir_pattern : file_dir_pattern;
        if (!pattern.is_empty ())
            pattern.append (QLatin1Char ('|'));
        pattern.append (append_me);
    };

    for (auto exclude : _all_excludes.value (base_path)) {
        if (exclude[0] == QLatin1Char ('\n'))
            continue; // empty line
        if (exclude[0] == QLatin1Char ('\r'))
            continue; // empty line

        bool match_dir_only = exclude.ends_with (QLatin1Char ('/'));
        if (match_dir_only)
            exclude = exclude.left (exclude.size () - 1);

        bool remove_excluded = (exclude[0] == QLatin1Char (']'));
        if (remove_excluded)
            exclude = exclude.mid (1);

        bool full_path = exclude.contains (QLatin1Char ('/'));

        /* Use QRegularExpression, append to the right pattern */
        auto &bname_file_dir = remove_excluded ? bname_file_dir_remove : bname_file_dir_keep;
        auto &bname_dir = remove_excluded ? bname_dir_remove : bname_dir_keep;
        auto &full_file_dir = remove_excluded ? full_file_dir_remove : full_file_dir_keep;
        auto &full_dir = remove_excluded ? full_dir_remove : full_dir_keep;

        if (full_path) {
            // The full pattern is matched against a path relative to _local_path, however exclude is
            // relative to base_path at this point.
            // We know for sure that both _local_path and base_path are absolute and that base_path is
            // contained in _local_path. So we can simply remove it from the begining.
            auto rel_path = base_path.mid (_local_path.size ());
            // Make exclude relative to _local_path
            exclude.prepend (rel_path);
        }
        auto regex_exclude = convert_to_regexp_syntax (exclude, _wildcards_match_slash);
        if (!full_path) {
            regex_append (bname_file_dir, bname_dir, regex_exclude, match_dir_only);
        } else {
            regex_append (full_file_dir, full_dir, regex_exclude, match_dir_only);

            // For activation, trigger on the 'bname' part of the full pattern.
            string bname_exclude = extract_bname_trigger (exclude, _wildcards_match_slash);
            auto regex_bname = convert_to_regexp_syntax (bname_exclude, true);
            regex_append (bname_trigger_file_dir, bname_trigger_dir, regex_bname, match_dir_only);
        }
    }

    // The empty pattern would match everything - change it to match-nothing
    auto empty_match_nothing = [] (string pattern) {
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
    _bname_traversal_regex_file[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1)$|"
                       "^ (?P<excluderemove>%2)$|"
                       "^ (?P<trigger>%3)$")
            .arg (bname_file_dir_keep, bname_file_dir_remove, bname_trigger_file_dir));
    _bname_traversal_regex_dir[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1|%2)$|"
                       "^ (?P<excluderemove>%3|%4)$|"
                       "^ (?P<trigger>%5|%6)$")
            .arg (bname_file_dir_keep, bname_dir_keep, bname_file_dir_remove, bname_dir_remove, bname_trigger_file_dir, bname_trigger_dir));

    // The full traveral regex is applied to the full path if the trigger capture of
    // the bname regex matches. Its basic form is (exclude)| (excluderemove)".
    // This pattern can be much simpler than full_regex since we can assume a traversal
    // situation and doesn't need to look for bname patterns in parent paths.
    _full_traversal_regex_file[base_path].set_pattern (
        // Full patterns are anchored to the beginning
        QStringLiteral ("^ (?P<exclude>%1) (?:$|/)"
                       "|"
                       "^ (?P<excluderemove>%2) (?:$|/)")
            .arg (full_file_dir_keep, full_file_dir_remove));
    _full_traversal_regex_dir[base_path].set_pattern (
        QStringLiteral ("^ (?P<exclude>%1|%2) (?:$|/)"
                       "|"
                       "^ (?P<excluderemove>%3|%4) (?:$|/)")
            .arg (full_file_dir_keep, full_dir_keep, full_file_dir_remove, full_dir_remove));

    // The full regex is applied to the full path and incorporates both bname and
    // full-path patterns. It has the form " (exclude)| (excluderemove)".
    _full_regex_file[base_path].set_pattern (
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
    _full_regex_dir[base_path].set_pattern (
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
    _bname_traversal_regex_file[base_path].set_pattern_options (pattern_options);
    _bname_traversal_regex_file[base_path].optimize ();
    _bname_traversal_regex_dir[base_path].set_pattern_options (pattern_options);
    _bname_traversal_regex_dir[base_path].optimize ();
    _full_traversal_regex_file[base_path].set_pattern_options (pattern_options);
    _full_traversal_regex_file[base_path].optimize ();
    _full_traversal_regex_dir[base_path].set_pattern_options (pattern_options);
    _full_traversal_regex_dir[base_path].optimize ();
    _full_regex_file[base_path].set_pattern_options (pattern_options);
    _full_regex_file[base_path].optimize ();
    _full_regex_dir[base_path].set_pattern_options (pattern_options);
    _full_regex_dir[base_path].optimize ();
}
