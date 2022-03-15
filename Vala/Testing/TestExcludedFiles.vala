/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QTemporaryDir>

using Occ;

namespace Testing {

public class TestExcludedFiles : GLib.Object {

    const string EXCLUDE_LIST_FILE SOURCEDIR = "/../../sync-exclude.lst"
    
    // The tests were converted from the old CMocka framework, that's why there is a global
    static ExcludedFiles excluded_files;
    
    static void up () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        excluded_files.set_wildcards_match_slash (false);
    }
    
    static void setup_init () {
        up ();
    
        excluded_files.add_exclude_file_path (EXCLUDE_LIST_FILE);
        GLib.assert_true (excluded_files.reload_exclude_files ());
    
        /* and add some unicode stuff */
        excluded_files.add_manual_exclude ("*.💩"); // is this source file utf8 encoded?
        excluded_files.add_manual_exclude ("пятницы.*");
        excluded_files.add_manual_exclude ("*/*.out");
        excluded_files.add_manual_exclude ("latex*/*.run.xml");
        excluded_files.add_manual_exclude ("latex/*/*.tex.tmp");
    
        GLib.assert_true (excluded_files.reload_exclude_files ());
    }

    static ExcludedFiles check_file_full (char path) {
        return excluded_files.full_pattern_match (path, ItemType.FILE);
    }

    static ExcludedFiles check_dir_full (char path) {
        return excluded_files.full_pattern_match (path, ItemType.DIRECTORY);
    }

    static ExcludedFiles check_file_traversal (char path) {
        return excluded_files.traversal_pattern_match (path, ItemType.FILE);
    }

    static ExcludedFiles check_dir_traversal (char path) {
        return excluded_files.traversal_pattern_match (path, ItemType.DIRECTORY);
    }

    private void test_fun () {
        ExcludedFiles excluded;
        bool exclude_hidden = true;
        bool keep_hidden = false;

        GLib.assert_true (!excluded.is_excluded ("/a/b", "/a", keep_hidden));
        GLib.assert_true (!excluded.is_excluded ("/a/b~", "/a", keep_hidden));
        GLib.assert_true (!excluded.is_excluded ("/a/.b", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/.b", "/a", exclude_hidden));

        excluded.add_exclude_file_path (EXCLUDE_LIST_FILE);
        excluded.reload_exclude_files ();

        GLib.assert_true (!excluded.is_excluded ("/a/b", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/b~", "/a", keep_hidden));
        GLib.assert_true (!excluded.is_excluded ("/a/.b", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/.Trashes", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/foo_conflict-bar", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/foo (conflicted copy bar)", "/a", keep_hidden));
        GLib.assert_true (excluded.is_excluded ("/a/.b", "/a", exclude_hidden));

        GLib.assert_true (excluded.is_excluded ("/a/#b#", "/a", keep_hidden));
    }

    private void check_csync_exclude_add () {
        up ();
        excluded_files.add_manual_exclude ("/tmp/check_csync1/*");
        GLib.assert_cmp (check_file_full ("/tmp/check_csync1/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("/tmp/check_csync2/foo"), CSYNC_NOT_EXCLUDED);
        GLib.assert_true (excluded_files.all_excludes["/"].contains ("/tmp/check_csync1/*"));

        GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("csync1"));
        GLib.assert_true (excluded_files.full_traversal_regex_file["/"].pattern ().contains ("csync1"));
        GLib.assert_true (!excluded_files.bname_traversal_regex_file["/"].pattern ().contains ("csync1"));

        excluded_files.add_manual_exclude ("foo");
        GLib.assert_true (excluded_files.bname_traversal_regex_file["/"].pattern ().contains ("foo"));
        GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("foo"));
        GLib.assert_true (!excluded_files.full_traversal_regex_file["/"].pattern ().contains ("foo"));
    }

    private void check_csync_exclude_add_per_dir () {
        up ();
        excluded_files.add_manual_exclude ("*", "/tmp/check_csync1/");
        GLib.assert_cmp (check_file_full ("/tmp/check_csync1/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("/tmp/check_csync2/foo"), CSYNC_NOT_EXCLUDED);
        GLib.assert_true (excluded_files.all_excludes["/tmp/check_csync1/"].contains ("*"));

        excluded_files.add_manual_exclude ("foo");
        GLib.assert_true (excluded_files.full_regex_file["/"].pattern ().contains ("foo"));

        excluded_files.add_manual_exclude ("foo/bar", "/tmp/check_csync1/");
        GLib.assert_true (excluded_files.full_regex_file["/tmp/check_csync1/"].pattern ().contains ("bar"));
        GLib.assert_true (excluded_files.full_traversal_regex_file["/tmp/check_csync1/"].pattern ().contains ("bar"));
        GLib.assert_true (!excluded_files.bname_traversal_regex_file["/tmp/check_csync1/"].pattern ().contains ("foo"));
    }

    private void check_csync_excluded () {
        setup_init ();
        GLib.assert_cmp (check_file_full (""), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("/"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("A"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("krawel_krawel"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full (".kde/share/config/kwin.eventsrc"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full (".directory/cache-maximegalon/cache1.txt"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("mozilla/.directory"), CSYNC_FILE_EXCLUDE_LIST);


        /***********************************************************
        * Test for patterns in subdirectories. '.beagle' is defined as a pattern and has
        * to be found in top directory as well as in directories underneath.
        */
        GLib.assert_cmp (check_dir_full (".apdisk"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("foo/.apdisk"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("foo/bar/.apdisk"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full (".java"), CSYNC_NOT_EXCLUDED);

        /* Files in the ignored directory .java will also be ignored. */
        GLib.assert_cmp (check_file_full (".apdisk/totally_amazing.jar"), CSYNC_FILE_EXCLUDE_LIST);

        /* and also in subdirectories */
        GLib.assert_cmp (check_file_full ("projects/.apdisk/totally_amazing.jar"), CSYNC_FILE_EXCLUDE_LIST);

        /* csync-journal is ignored in general silently. */
        GLib.assert_cmp (check_file_full (".csync_journal.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full (".csync_journal.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full ("subdir/.csync_journal.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        /* also the new form of the database name */
        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db-shm"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full ("subdir/.sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full (".sync_5bdd60bdfcfa.db-shm"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_full ("subdir/.sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        /* pattern ]*.directory - ignore and remove */
        GLib.assert_cmp (check_file_full ("my.~directory"), CSYNC_FILE_EXCLUDE_AND_REMOVE);
        GLib.assert_cmp (check_file_full ("/a_folder/my.~directory"), CSYNC_FILE_EXCLUDE_AND_REMOVE);

        /* Not excluded because the pattern .netscape/cache requires directory. */
        GLib.assert_cmp (check_file_full (".netscape/cache"), CSYNC_NOT_EXCLUDED);

        /* Not excluded  */
        GLib.assert_cmp (check_file_full ("unicode/中文.hé"), CSYNC_NOT_EXCLUDED);
        /* excluded  */
        GLib.assert_cmp (check_file_full ("unicode/пятницы.txt"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("unicode/中文.💩"), CSYNC_FILE_EXCLUDE_LIST);

        /* path wildcards */
        GLib.assert_cmp (check_file_full ("foobar/my_manuscript.out"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("latex_tmp/my_manuscript.run.xml"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full ("word_tmp/my_manuscript.run.xml"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_full ("latex/my_manuscript.tex.tmp"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_full ("latex/songbook/my_manuscript.tex.tmp"), CSYNC_FILE_EXCLUDE_LIST);

        /* ? character */
        excluded_files.add_manual_exclude ("bond00?");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_full ("bond00"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("bond007"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("bond0071"), CSYNC_NOT_EXCLUDED);

        /* brackets */
        excluded_files.add_manual_exclude ("a [bc] d");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_full ("a d d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a  d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a b d"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("a c d"), CSYNC_FILE_EXCLUDE_LIST);

        /* escapes */
        excluded_files.add_manual_exclude ("a \\*");
        excluded_files.add_manual_exclude ("b \\?");
        excluded_files.add_manual_exclude ("c \\[d]");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_full ("a \\*"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a bc"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a *"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("b \\?"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("b f"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("b ?"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("c \\[d]"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("c d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("c [d]"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_excluded_per_dir () {
        var temporary_directory = QStandardPaths.writable_location (QStandardPaths.TempLocation);
        excluded_files.on_signal_reset (new ExcludedFiles (temporary_directory + "/"));
        excluded_files.set_wildcards_match_slash (false);
        excluded_files.add_manual_exclude ("A");
        excluded_files.reload_exclude_files ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_FILE_EXCLUDE_LIST);

        excluded_files.clear_manual_excludes ();
        excluded_files.add_manual_exclude ("A", temporary_directory + "/B/");
        excluded_files.reload_exclude_files ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("B/A"), CSYNC_FILE_EXCLUDE_LIST);

        excluded_files.clear_manual_excludes ();
        excluded_files.add_manual_exclude ("A/a1", temporary_directory + "/B/");
        excluded_files.reload_exclude_files ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("B/A/a1"), CSYNC_FILE_EXCLUDE_LIST);

        const string foo_directory = "check_csync1/foo";
        GLib.assert_true (QDir (temporary_directory).mkpath (foo_directory));

        const string foo_exclude_list = temporary_directory + '/' + foo_directory + "/.sync-exclude.lst";
        GLib.File exclude_list = new GLib.File (foo_exclude_list);
        GLib.assert_true (exclude_list.open (GLib.File.WriteOnly));
        GLib.assert_cmp (exclude_list.write ("bar"), 3);
        exclude_list.close ();

        excluded_files.add_exclude_file_path (foo_exclude_list);
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_full (string (foo_directory + "/bar")), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full (string (foo_directory + "/baz")), CSYNC_NOT_EXCLUDED);
    }

    private void check_csync_excluded_traversal_per_dir () {
        setup_init ();
        GLib.assert_cmp (check_file_traversal ("/"), CSYNC_NOT_EXCLUDED);

        /* path wildcards */
        excluded_files.add_manual_exclude ("*/*.tex.tmp", "/latex/");
        GLib.assert_cmp (check_file_traversal ("latex/my_manuscript.tex.tmp"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("latex/songbook/my_manuscript.tex.tmp"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_excluded_traversal () {
        setup_init ();
        GLib.assert_cmp (check_file_traversal (""), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("/"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("A"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("krawel_krawel"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".kde/share/config/kwin.eventsrc"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_dir_traversal ("mozilla/.directory"), CSYNC_FILE_EXCLUDE_LIST);


        /***********************************************************
        * Test for patterns in subdirectories. '.beagle' is defined as a pattern and has
        * to be found in top directory as well as in directories underneath.
        */
        GLib.assert_cmp (check_dir_traversal (".apdisk"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("foo/.apdisk"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("foo/bar/.apdisk"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_traversal (".java"), CSYNC_NOT_EXCLUDED);

        /* csync-journal is ignored in general silently. */
        GLib.assert_cmp (check_file_traversal (".csync_journal.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".csync_journal.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("subdir/.csync_journal.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("/two/subdir/.csync_journal.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        /* also the new form of the database name */
        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db-shm"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("subdir/.sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db.ctmp"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal (".sync_5bdd60bdfcfa.db-shm"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("subdir/.sync_5bdd60bdfcfa.db"), CSYNC_FILE_SILENTLY_EXCLUDED);

        /* Other builtin excludes */
        GLib.assert_cmp (check_file_traversal ("foo/Desktop.ini"), CSYNC_FILE_SILENTLY_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("Desktop.ini"), CSYNC_FILE_SILENTLY_EXCLUDED);

        /* pattern ]*.directory - ignore and remove */
        GLib.assert_cmp (check_file_traversal ("my.~directory"), CSYNC_FILE_EXCLUDE_AND_REMOVE);
        GLib.assert_cmp (check_file_traversal ("/a_folder/my.~directory"), CSYNC_FILE_EXCLUDE_AND_REMOVE);

        /* Not excluded because the pattern .netscape/cache requires directory. */
        GLib.assert_cmp (check_file_traversal (".netscape/cache"), CSYNC_NOT_EXCLUDED);

        /* Not excluded  */
        GLib.assert_cmp (check_file_traversal ("unicode/中文.hé"), CSYNC_NOT_EXCLUDED);
        /* excluded  */
        GLib.assert_cmp (check_file_traversal ("unicode/пятницы.txt"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("unicode/中文.💩"), CSYNC_FILE_EXCLUDE_LIST);

        /* path wildcards */
        GLib.assert_cmp (check_file_traversal ("foobar/my_manuscript.out"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("latex_tmp/my_manuscript.run.xml"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("word_tmp/my_manuscript.run.xml"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("latex/my_manuscript.tex.tmp"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("latex/songbook/my_manuscript.tex.tmp"), CSYNC_FILE_EXCLUDE_LIST);

        /* From here the actual traversal tests */

        excluded_files.add_manual_exclude ("/exclude");
        excluded_files.reload_exclude_files ();

        /* Check toplevel directory, the pattern only works for toplevel directory. */
        GLib.assert_cmp (check_dir_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* check for a file called exclude. Must still work */
        GLib.assert_cmp (check_file_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* Add an exclude for directories only : excl/ */
        excluded_files.add_manual_exclude ("excl/");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_dir_traversal ("/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("meep/excl"), CSYNC_FILE_EXCLUDE_LIST);

        // because leading dirs aren't checked!
        GLib.assert_cmp (check_file_traversal ("meep/excl/file"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("/excl"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        excluded_files.reload_exclude_files ();

        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir2"), CSYNC_NOT_EXCLUDED);

        // because leading dirs aren't checked!
        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir/foo"), CSYNC_NOT_EXCLUDED);

        /* Check ending of pattern */
        GLib.assert_cmp (check_file_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/exclude_x"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("exclude"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("exclude");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_traversal ("exclude"), CSYNC_FILE_EXCLUDE_LIST);

        /* ? character */
        excluded_files.add_manual_exclude ("bond00?");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_traversal ("bond00"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("bond007"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("bond0071"), CSYNC_NOT_EXCLUDED);

        /* brackets */
        excluded_files.add_manual_exclude ("a [bc] d");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_traversal ("a d d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a  d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a b d"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("a c d"), CSYNC_FILE_EXCLUDE_LIST);

        /* escapes */
        excluded_files.add_manual_exclude ("a \\*");
        excluded_files.add_manual_exclude ("b \\?");
        excluded_files.add_manual_exclude ("c \\[d]");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_file_traversal ("a \\*"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a bc"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a *"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("b \\?"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("b f"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("b ?"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("c \\[d]"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("c d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("c [d]"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_dir_only () {
        up ();
        excluded_files.add_manual_exclude ("filedir");
        excluded_files.add_manual_exclude ("directory/");

        GLib.assert_cmp (check_file_traversal ("other"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("filedir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("directory"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("s/other"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("s/filedir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("s/directory"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_dir_traversal ("other"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_dir_traversal ("filedir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("directory"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("s/other"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_dir_traversal ("s/filedir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("s/directory"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_dir_full ("filedir/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("filedir/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("directory/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("directory/foo"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_pathes () {
        setup_init ();
        excluded_files.add_manual_exclude ("/exclude");
        excluded_files.reload_exclude_files ();

        /* Check toplevel directory, the pattern only works for toplevel directory. */
        GLib.assert_cmp (check_dir_full ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_dir_full ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* check for a file called exclude. Must still work */
        GLib.assert_cmp (check_file_full ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* Add an exclude for directories only : excl/ */
        excluded_files.add_manual_exclude ("excl/");
        excluded_files.reload_exclude_files ();
        GLib.assert_cmp (check_dir_full ("/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("meep/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("meep/excl/file"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full ("/excl"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        excluded_files.reload_exclude_files ();

        GLib.assert_cmp (check_dir_full ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_dir_full ("/excludepath/withsubdir2"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_dir_full ("/excludepath/withsubdir/foo"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_wildcards () {
        up ();
        excluded_files.add_manual_exclude ("a/foo*bar");
        excluded_files.add_manual_exclude ("b/foo*bar*");
        excluded_files.add_manual_exclude ("c/foo?bar");
        excluded_files.add_manual_exclude ("d/foo?bar*");
        excluded_files.add_manual_exclude ("e/foo?bar?");
        excluded_files.add_manual_exclude ("g/bar*");
        excluded_files.add_manual_exclude ("h/bar?");

        excluded_files.set_wildcards_match_slash (false);

        GLib.assert_cmp (check_file_traversal ("a/foo_xyz_bar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("a/foo_x/z_bar"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("b/foo_xyz_bar_abc"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("b/foo_x/z_bar_abc"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("c/foo_x_bar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("c/foo/bar"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("d/foo_x_bar_abc"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("d/foo/bar_abc"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("e/foo_x_bar_a"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("e/foo/bar_a"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("g/bar_abc"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("g/x_bar_abc"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("h/bar_z"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("h/x_bar_z"), CSYNC_NOT_EXCLUDED);

        excluded_files.set_wildcards_match_slash (true);

        GLib.assert_cmp (check_file_traversal ("a/foo_x/z_bar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("b/foo_x/z_bar_abc"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("c/foo/bar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("d/foo/bar_abc"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("e/foo/bar_a"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_regex_translation () {
        up ();
        string storage;
        var translate = [&storage] (char pattern) {
            storage = ExcludedFiles.convert_to_regexp_syntax (pattern, false);
            return storage.const_data ();
        }

        GLib.assert_cmp (translate (""), "");
        GLib.assert_cmp (translate ("abc"), "abc");
        GLib.assert_cmp (translate ("a*c"), "a[^/]*c");
        GLib.assert_cmp (translate ("a?c"), "a[^/]c");
        GLib.assert_cmp (translate ("a[xyz]c"), "a[xyz]c");
        GLib.assert_cmp (translate ("a[xyzc"), "a\\[xyzc");
        GLib.assert_cmp (translate ("a[!xyz]c"), "a[^xyz]c");
        GLib.assert_cmp (translate ("a\\*b\\?c\\[d\\\\e"), "a\\*b\\?c\\[d\\\\e");
        GLib.assert_cmp (translate ("a.c"), "a\\.c");
        GLib.assert_cmp (translate ("?𠜎?"), "[^/]\\𠜎[^/]"); // 𠜎 is 4-byte utf8
    }

    private void check_csync_bname_trigger () {
        up ();
        bool wildcards_match_slash = false;
        string storage;
        var translate = [&storage, wildcards_match_slash] (char pattern) => {
            storage = ExcludedFiles.extract_bname_trigger (pattern, wildcards_match_slash);
            return storage.const_data ();
        }

        GLib.assert_cmp (translate (""), "");
        GLib.assert_cmp (translate ("a/b/"), "");
        GLib.assert_cmp (translate ("a/b/c"), "c");
        GLib.assert_cmp (translate ("c"), "c");
        GLib.assert_cmp (translate ("a/foo*"), "foo*");
        GLib.assert_cmp (translate ("a/abc*foo*"), "abc*foo*");

        wildcards_match_slash = true;

        GLib.assert_cmp (translate (""), "");
        GLib.assert_cmp (translate ("a/b/"), "");
        GLib.assert_cmp (translate ("a/b/c"), "c");
        GLib.assert_cmp (translate ("c"), "c");
        GLib.assert_cmp (translate ("*"), "*");
        GLib.assert_cmp (translate ("a/foo*"), "foo*");
        GLib.assert_cmp (translate ("a/abc?foo*"), "*foo*");
        GLib.assert_cmp (translate ("a/abc*foo*"), "*foo*");
        GLib.assert_cmp (translate ("a/abc?foo?"), "*foo?");
        GLib.assert_cmp (translate ("a/abc*foo?*"), "*foo?*");
        GLib.assert_cmp (translate ("a/abc*/foo*"), "foo*");
    }

    private void check_csync_is_windows_reserved_word () {
        var csync_is_windows_reserved_word = [] (char fn) {
            string s = fn;
            extern bool csync_is_windows_reserved_word (QStringRef filename);
            return csync_is_windows_reserved_word (&s);
        }

        GLib.assert_true (csync_is_windows_reserved_word ("CON"));
        GLib.assert_true (csync_is_windows_reserved_word ("con"));
        GLib.assert_true (csync_is_windows_reserved_word ("CON."));
        GLib.assert_true (csync_is_windows_reserved_word ("con."));
        GLib.assert_true (csync_is_windows_reserved_word ("CON.ference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("CONference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("conference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("conf.erence"));
        GLib.assert_true (!csync_is_windows_reserved_word ("co"));

        GLib.assert_true (csync_is_windows_reserved_word ("COM2"));
        GLib.assert_true (csync_is_windows_reserved_word ("com2"));
        GLib.assert_true (csync_is_windows_reserved_word ("COM2."));
        GLib.assert_true (csync_is_windows_reserved_word ("com2."));
        GLib.assert_true (csync_is_windows_reserved_word ("COM2.ference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("COM2ference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("com2ference"));
        GLib.assert_true (!csync_is_windows_reserved_word ("com2f.erence"));
        GLib.assert_true (!csync_is_windows_reserved_word ("com"));

        GLib.assert_true (csync_is_windows_reserved_word ("CLOCK$"));
        GLib.assert_true (csync_is_windows_reserved_word ("$Recycle.Bin"));
        GLib.assert_true (csync_is_windows_reserved_word ("ClocK$"));
        GLib.assert_true (csync_is_windows_reserved_word ("$recycle.bin"));

        GLib.assert_true (csync_is_windows_reserved_word ("A:"));
        GLib.assert_true (csync_is_windows_reserved_word ("a:"));
        GLib.assert_true (csync_is_windows_reserved_word ("z:"));
        GLib.assert_true (csync_is_windows_reserved_word ("Z:"));
        GLib.assert_true (csync_is_windows_reserved_word ("M:"));
        GLib.assert_true (csync_is_windows_reserved_word ("m:"));
    }

    /* QT_ENABLE_REGEXP_JIT=0 to get slower results :-) */
    private void check_csync_excluded_performance1 () {
        setup_init ();
        const int N = 1000;
        int total_rc = 0;

        QBENCHMARK {

            for (int i = 0; i < N; ++i) {
                total_rc += check_dir_full ("/this/is/quite/a/long/path/with/many/components");
                total_rc += check_file_full ("/1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/29");
            }
            GLib.assert_cmp (total_rc, 0); // mainly to avoid optimization
        }
    }


    /***********************************************************
    ***********************************************************/
    private void check_csync_excluded_performance2 () {
        const int N = 1000;
        int total_rc = 0;

        QBENCHMARK {
            for (int i = 0; i < N; ++i) {
                total_rc += check_dir_traversal ("/this/is/quite/a/long/path/with/many/components");
                total_rc += check_file_traversal ("/1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/29");
            }
            GLib.assert_cmp (total_rc, 0); // mainly to avoid optimization
        }
    }


    /***********************************************************
    ***********************************************************/
    private void check_csync_exclude_expand_escapes () {
        extern void csync_exclude_expand_escapes (string input);

        string line = R" (keep \' \" \? \\ \a \b \f \n \r \t \v \z \#)";
        csync_exclude_expand_escapes (line);
        GLib.assert_true (0 == strcmp (line.const_data (), "keep ' \" ? \\\\ \a \b \f \n \r \t \v \\z #"));

        line = "";
        csync_exclude_expand_escapes (line);
        GLib.assert_true (0 == strcmp (line.const_data (), ""));

        line = "\\";
        csync_exclude_expand_escapes (line);
        GLib.assert_true (0 == strcmp (line.const_data (), "\\"));
    }


    /***********************************************************
    ***********************************************************/
    private void check_version_directive () {
        ExcludedFiles excludes;
        excludes.set_client_version (ExcludedFiles.Version (2, 5, 0));

        GLib.Vector<std.pair<const char *, bool>> tests = { { "#!version == 2.5.0", true }, { "#!version == 2.6.0", false }, { "#!version < 2.6.0", true }, { "#!version <= 2.6.0", true }, { "#!version > 2.6.0", false }, { "#!version >= 2.6.0", false }, { "#!version < 2.4.0", false }, { "#!version <= 2.4.0", false }, { "#!version > 2.4.0", true }, { "#!version >= 2.4.0", true }, { "#!version < 2.5.0", false }, { "#!version <= 2.5.0", true }, { "#!version > 2.5.0", false }, { "#!version >= 2.5.0", true },
        }
        for (var test : tests) {
            GLib.assert_true (excludes.version_directive_keep_next_line (test.first) == test.second);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void test_add_exclude_file_path_add_same_file_path_list_size_does_not_increase () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        var file_path = "exclude/.sync-exclude.lst";

        excluded_files.add_exclude_file_path (file_path);
        excluded_files.add_exclude_file_path (file_path);

        GLib.assert_cmp (excluded_files.exclude_files.size (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void test_add_exclude_file_path_add_different_file_paths_list_size_increase () {
        excluded_files.on_signal_reset (new ExcludedFiles ());

        var file_path1 = "exclude1/.sync-exclude.lst";
        var file_path2 = "exclude2/.sync-exclude.lst";

        excluded_files.add_exclude_file_path (file_path1);
        excluded_files.add_exclude_file_path (file_path2);

        GLib.assert_cmp (excluded_files.exclude_files.size (), 2);
    }


    /***********************************************************
    ***********************************************************/
    private void test_add_exclude_file_path_add_default_exclude_file_return_correct_map () {
        const string base_path = "sync_folder/";
        const string folder1 = "sync_folder/folder1/";
        const string folder2 = folder1 + "folder2/";
        excluded_files.on_signal_reset (new ExcludedFiles (base_path));

        const string default_exclude_list = "desktop-client/config-folder/sync-exclude.lst";
        const string folder1_exclude_list = folder1 + ".sync-exclude.lst";
        const string folder2_exclude_list = folder2 + ".sync-exclude.lst";

        excluded_files.add_exclude_file_path (default_exclude_list);
        excluded_files.add_exclude_file_path (folder1_exclude_list);
        excluded_files.add_exclude_file_path (folder2_exclude_list);

        GLib.assert_cmp (excluded_files.exclude_files.size (), 3);
        GLib.assert_cmp (excluded_files.exclude_files[base_path].first (), default_exclude_list);
        GLib.assert_cmp (excluded_files.exclude_files[folder1].first (), folder1_exclude_list);
        GLib.assert_cmp (excluded_files.exclude_files[folder2].first (), folder2_exclude_list);
    }


    /***********************************************************
    ***********************************************************/
    private void test_reload_exclude_files_file_does_not_exist_return_false () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        const string non_existing_file = "directory/.sync-exclude.lst";
        excluded_files.add_exclude_file_path (non_existing_file);
        GLib.assert_cmp (excluded_files.reload_exclude_files (), false);
        GLib.assert_cmp (excluded_files.all_excludes.size (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private void test_reload_exclude_files_file_exists_return_true () {
        var temporary_directory = QStandardPaths.writable_location (QStandardPaths.TempLocation);
        excluded_files.on_signal_reset (new ExcludedFiles (temporary_directory + "/"));

        const string sub_temp_dir = "exclude";
        GLib.assert_true (QDir (temporary_directory).mkpath (sub_temp_dir));

        string existing_file_path = temporary_directory + '/' + sub_temp_dir + "/.sync-exclude.lst";
        GLib.File exclude_list = new GLib.File (existing_file_path);
        GLib.assert_true (exclude_list.open (GLib.File.WriteOnly));
        exclude_list.close ();

        excluded_files.add_exclude_file_path (existing_file_path);
        GLib.assert_cmp (excluded_files.reload_exclude_files (), true);
        GLib.assert_cmp (excluded_files.all_excludes.size (), 1);
    }

} // class TestExcludedFiles
} // namespace Testing
