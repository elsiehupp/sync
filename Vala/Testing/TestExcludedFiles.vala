/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <QTemporaryDir>

using Occ;

namespace Testing {

class TestExcludedFiles : GLib.Object {

    const string EXCLUDE_LIST_FILE SOURCEDIR = "/../../sync-exclude.lst"
    
    // The tests were converted from the old CMocka framework, that's why there is a global
    static ExcludedFiles excluded_files;
    
    static void up () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        excluded_files.setWildcardsMatchSlash (false);
    }
    
    static void setup_init () {
        up ();
    
        excluded_files.addExcludeFilePath (EXCLUDE_LIST_FILE);
        GLib.assert_true (excluded_files.reloadExcludeFiles ());
    
        /* and add some unicode stuff */
        excluded_files.add_manual_exclude ("*.💩"); // is this source file utf8 encoded?
        excluded_files.add_manual_exclude ("пятницы.*");
        excluded_files.add_manual_exclude ("*/*.out");
        excluded_files.add_manual_exclude ("latex*/*.run.xml");
        excluded_files.add_manual_exclude ("latex/*/*.tex.tmp");
    
        GLib.assert_true (excluded_files.reloadExcludeFiles ());
    }

    static ExcludedFiles check_file_full (char path) {
        return excluded_files.fullPatternMatch (path, ItemTypeFile);
    }

    static ExcludedFiles check_dir_full (char path) {
        return excluded_files.fullPatternMatch (path, ItemTypeDirectory);
    }

    static ExcludedFiles check_file_traversal (char path) {
        return excluded_files.traversalPatternMatch (path, ItemTypeFile);
    }

    static ExcludedFiles check_dir_traversal (char path) {
        return excluded_files.traversalPatternMatch (path, ItemTypeDirectory);
    }

    private void testFun () {
        ExcludedFiles excluded;
        bool excludeHidden = true;
        bool keepHidden = false;

        GLib.assert_true (!excluded.isExcluded ("/a/b", "/a", keepHidden));
        GLib.assert_true (!excluded.isExcluded ("/a/b~", "/a", keepHidden));
        GLib.assert_true (!excluded.isExcluded ("/a/.b", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/.b", "/a", excludeHidden));

        excluded.addExcludeFilePath (EXCLUDE_LIST_FILE);
        excluded.reloadExcludeFiles ();

        GLib.assert_true (!excluded.isExcluded ("/a/b", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/b~", "/a", keepHidden));
        GLib.assert_true (!excluded.isExcluded ("/a/.b", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/.Trashes", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/foo_conflict-bar", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/foo (conflicted copy bar)", "/a", keepHidden));
        GLib.assert_true (excluded.isExcluded ("/a/.b", "/a", excludeHidden));

        GLib.assert_true (excluded.isExcluded ("/a/#b#", "/a", keepHidden));
    }

    private void check_csync_exclude_add () {
        up ();
        excluded_files.add_manual_exclude ("/tmp/check_csync1/*");
        GLib.assert_cmp (check_file_full ("/tmp/check_csync1/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("/tmp/check_csync2/foo"), CSYNC_NOT_EXCLUDED);
        GLib.assert_true (excluded_files.allExcludes["/"].contains ("/tmp/check_csync1/*"));

        GLib.assert_true (excluded_files.fullRegexFile["/"].pattern ().contains ("csync1"));
        GLib.assert_true (excluded_files.fullTraversalRegexFile["/"].pattern ().contains ("csync1"));
        GLib.assert_true (!excluded_files.bnameTraversalRegexFile["/"].pattern ().contains ("csync1"));

        excluded_files.add_manual_exclude ("foo");
        GLib.assert_true (excluded_files.bnameTraversalRegexFile["/"].pattern ().contains ("foo"));
        GLib.assert_true (excluded_files.fullRegexFile["/"].pattern ().contains ("foo"));
        GLib.assert_true (!excluded_files.fullTraversalRegexFile["/"].pattern ().contains ("foo"));
    }

    private void check_csync_exclude_add_per_dir () {
        up ();
        excluded_files.add_manual_exclude ("*", "/tmp/check_csync1/");
        GLib.assert_cmp (check_file_full ("/tmp/check_csync1/foo"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("/tmp/check_csync2/foo"), CSYNC_NOT_EXCLUDED);
        GLib.assert_true (excluded_files.allExcludes["/tmp/check_csync1/"].contains ("*"));

        excluded_files.add_manual_exclude ("foo");
        GLib.assert_true (excluded_files.fullRegexFile["/"].pattern ().contains ("foo"));

        excluded_files.add_manual_exclude ("foo/bar", "/tmp/check_csync1/");
        GLib.assert_true (excluded_files.fullRegexFile["/tmp/check_csync1/"].pattern ().contains ("bar"));
        GLib.assert_true (excluded_files.fullTraversalRegexFile["/tmp/check_csync1/"].pattern ().contains ("bar"));
        GLib.assert_true (!excluded_files.bnameTraversalRegexFile["/tmp/check_csync1/"].pattern ().contains ("foo"));
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
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_full ("bond00"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("bond007"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("bond0071"), CSYNC_NOT_EXCLUDED);

        /* brackets */
        excluded_files.add_manual_exclude ("a [bc] d");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_full ("a d d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a  d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("a b d"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("a c d"), CSYNC_FILE_EXCLUDE_LIST);

        /* escapes */
        excluded_files.add_manual_exclude ("a \\*");
        excluded_files.add_manual_exclude ("b \\?");
        excluded_files.add_manual_exclude ("c \\[d]");
        excluded_files.reloadExcludeFiles ();
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
        var temporary_directory = QStandardPaths.writableLocation (QStandardPaths.TempLocation);
        excluded_files.on_signal_reset (new ExcludedFiles (temporary_directory + "/"));
        excluded_files.setWildcardsMatchSlash (false);
        excluded_files.add_manual_exclude ("A");
        excluded_files.reloadExcludeFiles ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_FILE_EXCLUDE_LIST);

        excluded_files.clearManualExcludes ();
        excluded_files.add_manual_exclude ("A", temporary_directory + "/B/");
        excluded_files.reloadExcludeFiles ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("B/A"), CSYNC_FILE_EXCLUDE_LIST);

        excluded_files.clearManualExcludes ();
        excluded_files.add_manual_exclude ("A/a1", temporary_directory + "/B/");
        excluded_files.reloadExcludeFiles ();

        GLib.assert_cmp (check_file_full ("A"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_full ("B/A/a1"), CSYNC_FILE_EXCLUDE_LIST);

        const string foo_directory = "check_csync1/foo";
        GLib.assert_true (QDir (temporary_directory).mkpath (foo_directory));

        const string foo_exclude_list = temporary_directory + '/' + foo_directory + "/.sync-exclude.lst";
        GLib.File excludeList = new GLib.File (foo_exclude_list);
        GLib.assert_true (excludeList.open (GLib.File.WriteOnly));
        GLib.assert_cmp (excludeList.write ("bar"), 3);
        excludeList.close ();

        excluded_files.addExcludeFilePath (foo_exclude_list);
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_full (GLib.ByteArray (foo_directory + "/bar")), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full (GLib.ByteArray (foo_directory + "/baz")), CSYNC_NOT_EXCLUDED);
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
        excluded_files.reloadExcludeFiles ();

        /* Check toplevel directory, the pattern only works for toplevel directory. */
        GLib.assert_cmp (check_dir_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* check for a file called exclude. Must still work */
        GLib.assert_cmp (check_file_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* Add an exclude for directories only : excl/ */
        excluded_files.add_manual_exclude ("excl/");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_dir_traversal ("/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("meep/excl"), CSYNC_FILE_EXCLUDE_LIST);

        // because leading dirs aren't checked!
        GLib.assert_cmp (check_file_traversal ("meep/excl/file"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("/excl"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        excluded_files.reloadExcludeFiles ();

        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/excludepath/withsubdir"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir2"), CSYNC_NOT_EXCLUDED);

        // because leading dirs aren't checked!
        GLib.assert_cmp (check_dir_traversal ("/excludepath/withsubdir/foo"), CSYNC_NOT_EXCLUDED);

        /* Check ending of pattern */
        GLib.assert_cmp (check_file_traversal ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("/excludeX"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("exclude"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("exclude");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_traversal ("exclude"), CSYNC_FILE_EXCLUDE_LIST);

        /* ? character */
        excluded_files.add_manual_exclude ("bond00?");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_traversal ("bond00"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("bond007"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("bond0071"), CSYNC_NOT_EXCLUDED);

        /* brackets */
        excluded_files.add_manual_exclude ("a [bc] d");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_file_traversal ("a d d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a  d"), CSYNC_NOT_EXCLUDED);
        GLib.assert_cmp (check_file_traversal ("a b d"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("a c d"), CSYNC_FILE_EXCLUDE_LIST);

        /* escapes */
        excluded_files.add_manual_exclude ("a \\*");
        excluded_files.add_manual_exclude ("b \\?");
        excluded_files.add_manual_exclude ("c \\[d]");
        excluded_files.reloadExcludeFiles ();
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
        excluded_files.reloadExcludeFiles ();

        /* Check toplevel directory, the pattern only works for toplevel directory. */
        GLib.assert_cmp (check_dir_full ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_dir_full ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* check for a file called exclude. Must still work */
        GLib.assert_cmp (check_file_full ("/exclude"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full ("/foo/exclude"), CSYNC_NOT_EXCLUDED);

        /* Add an exclude for directories only : excl/ */
        excluded_files.add_manual_exclude ("excl/");
        excluded_files.reloadExcludeFiles ();
        GLib.assert_cmp (check_dir_full ("/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_dir_full ("meep/excl"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_full ("meep/excl/file"), CSYNC_FILE_EXCLUDE_LIST);

        GLib.assert_cmp (check_file_full ("/excl"), CSYNC_NOT_EXCLUDED);

        excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        excluded_files.reloadExcludeFiles ();

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

        excluded_files.setWildcardsMatchSlash (false);

        GLib.assert_cmp (check_file_traversal ("a/fooXYZbar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("a/fooX/Zbar"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("b/fooXYZbarABC"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("b/fooX/ZbarABC"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("c/fooXbar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("c/foo/bar"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("d/fooXbarABC"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("d/foo/barABC"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("e/fooXbarA"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("e/foo/barA"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("g/barABC"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("g/XbarABC"), CSYNC_NOT_EXCLUDED);

        GLib.assert_cmp (check_file_traversal ("h/barZ"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("h/XbarZ"), CSYNC_NOT_EXCLUDED);

        excluded_files.setWildcardsMatchSlash (true);

        GLib.assert_cmp (check_file_traversal ("a/fooX/Zbar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("b/fooX/ZbarABC"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("c/foo/bar"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("d/foo/barABC"), CSYNC_FILE_EXCLUDE_LIST);
        GLib.assert_cmp (check_file_traversal ("e/foo/barA"), CSYNC_FILE_EXCLUDE_LIST);
    }

    private void check_csync_regex_translation () {
        up ();
        GLib.ByteArray storage;
        var translate = [&storage] (char pattern) {
            storage = ExcludedFiles.convertToRegexpSyntax (pattern, false);
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
        bool wildcardsMatchSlash = false;
        GLib.ByteArray storage;
        var translate = [&storage, wildcardsMatchSlash] (char pattern) => {
            storage = ExcludedFiles.extractBnameTrigger (pattern, wildcardsMatchSlash);
            return storage.const_data ();
        }

        GLib.assert_cmp (translate (""), "");
        GLib.assert_cmp (translate ("a/b/"), "");
        GLib.assert_cmp (translate ("a/b/c"), "c");
        GLib.assert_cmp (translate ("c"), "c");
        GLib.assert_cmp (translate ("a/foo*"), "foo*");
        GLib.assert_cmp (translate ("a/abc*foo*"), "abc*foo*");

        wildcardsMatchSlash = true;

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
            string s = string.fromLatin1 (fn);
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
        int totalRc = 0;

        QBENCHMARK {

            for (int i = 0; i < N; ++i) {
                totalRc += check_dir_full ("/this/is/quite/a/long/path/with/many/components");
                totalRc += check_file_full ("/1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/29");
            }
            GLib.assert_cmp (totalRc, 0); // mainly to avoid optimization
        }
    }


    /***********************************************************
    ***********************************************************/
    private void check_csync_excluded_performance2 () {
        const int N = 1000;
        int totalRc = 0;

        QBENCHMARK {
            for (int i = 0; i < N; ++i) {
                totalRc += check_dir_traversal ("/this/is/quite/a/long/path/with/many/components");
                totalRc += check_file_traversal ("/1/2/3/4/5/6/7/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/23/24/25/26/27/29");
            }
            GLib.assert_cmp (totalRc, 0); // mainly to avoid optimization
        }
    }


    /***********************************************************
    ***********************************************************/
    private void check_csync_exclude_expand_escapes () {
        extern void csync_exclude_expand_escapes (GLib.ByteArray input);

        GLib.ByteArray line = R" (keep \' \" \? \\ \a \b \f \n \r \t \v \z \#)";
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
        excludes.setClientVersion (ExcludedFiles.Version (2, 5, 0));

        GLib.Vector<std.pair<const char *, bool>> tests = { { "#!version == 2.5.0", true }, { "#!version == 2.6.0", false }, { "#!version < 2.6.0", true }, { "#!version <= 2.6.0", true }, { "#!version > 2.6.0", false }, { "#!version >= 2.6.0", false }, { "#!version < 2.4.0", false }, { "#!version <= 2.4.0", false }, { "#!version > 2.4.0", true }, { "#!version >= 2.4.0", true }, { "#!version < 2.5.0", false }, { "#!version <= 2.5.0", true }, { "#!version > 2.5.0", false }, { "#!version >= 2.5.0", true },
        }
        for (var test : tests) {
            GLib.assert_true (excludes.versionDirectiveKeepNextLine (test.first) == test.second);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void testAddExcludeFilePath_addSameFilePath_listSizeDoesNotIncrease () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        var file_path = string ("exclude/.sync-exclude.lst");

        excluded_files.addExcludeFilePath (file_path);
        excluded_files.addExcludeFilePath (file_path);

        GLib.assert_cmp (excluded_files.excludeFiles.size (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void testAddExcludeFilePath_addDifferentFilePaths_listSizeIncrease () {
        excluded_files.on_signal_reset (new ExcludedFiles ());

        var filePath1 = string ("exclude1/.sync-exclude.lst");
        var filePath2 = string ("exclude2/.sync-exclude.lst");

        excluded_files.addExcludeFilePath (filePath1);
        excluded_files.addExcludeFilePath (filePath2);

        GLib.assert_cmp (excluded_files.excludeFiles.size (), 2);
    }


    /***********************************************************
    ***********************************************************/
    private void testAddExcludeFilePath_addDefaultExcludeFile_returnCorrectMap () {
        const string basePath ("syncFolder/");
        const string folder1 ("syncFolder/folder1/");
        const string folder2 (folder1 + "folder2/");
        excluded_files.on_signal_reset (new ExcludedFiles (basePath));

        const string defaultExcludeList ("desktop-client/config-folder/sync-exclude.lst");
        const string folder1ExcludeList (folder1 + ".sync-exclude.lst");
        const string folder2ExcludeList (folder2 + ".sync-exclude.lst");

        excluded_files.addExcludeFilePath (defaultExcludeList);
        excluded_files.addExcludeFilePath (folder1ExcludeList);
        excluded_files.addExcludeFilePath (folder2ExcludeList);

        GLib.assert_cmp (excluded_files.excludeFiles.size (), 3);
        GLib.assert_cmp (excluded_files.excludeFiles[basePath].first (), defaultExcludeList);
        GLib.assert_cmp (excluded_files.excludeFiles[folder1].first (), folder1ExcludeList);
        GLib.assert_cmp (excluded_files.excludeFiles[folder2].first (), folder2ExcludeList);
    }


    /***********************************************************
    ***********************************************************/
    private void testReloadExcludeFiles_fileDoesNotExist_return_false () {
        excluded_files.on_signal_reset (new ExcludedFiles ());
        const string nonExistingFile ("directory/.sync-exclude.lst");
        excluded_files.addExcludeFilePath (nonExistingFile);
        GLib.assert_cmp (excluded_files.reloadExcludeFiles (), false);
        GLib.assert_cmp (excluded_files.allExcludes.size (), 0);
    }


    /***********************************************************
    ***********************************************************/
    private void testReloadExcludeFiles_fileExists_return_true () {
        var temporary_directory = QStandardPaths.writableLocation (QStandardPaths.TempLocation);
        excluded_files.on_signal_reset (new ExcludedFiles (temporary_directory + "/"));

        const string subTempDir = "exclude";
        GLib.assert_true (QDir (temporary_directory).mkpath (subTempDir));

        var existingFilePath = string (temporary_directory + '/' + subTempDir + "/.sync-exclude.lst");
        GLib.File excludeList (existingFilePath);
        GLib.assert_true (excludeList.open (GLib.File.WriteOnly));
        excludeList.close ();

        excluded_files.addExcludeFilePath (existingFilePath);
        GLib.assert_cmp (excluded_files.reloadExcludeFiles (), true);
        GLib.assert_cmp (excluded_files.allExcludes.size (), 1);
    }

} // class TestExcludedFiles
} // namespace Testing
