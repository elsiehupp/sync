namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludedTraversal

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludedTraversal : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExcludedTraversal () {
        //  base ();
        //  GLib.assert_true (check_file_traversal ("") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("/") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  GLib.assert_true (check_file_traversal ("A") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  GLib.assert_true (check_file_traversal ("krawel_krawel") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal (".kde/share/config/kwin.eventsrc") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_dir_traversal ("mozilla/.directory") == CSync.CSync.ExcludedFiles.Type.LIST);


        //  /***********************************************************
        //  Test for patterns in subdirectories. '.beagle' is defined as
        //  a pattern and has to be found in top directory as well as in
        //  directories underneath.
        //  ***********************************************************/
        //  GLib.assert_true (check_dir_traversal (".apdisk") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_traversal ("foo/.apdisk") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_traversal ("foo/bar/.apdisk") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  GLib.assert_true (check_file_traversal (".java") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* csync-journal is ignored in general silently. */
        //  GLib.assert_true (check_file_traversal (".csync_journal.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal (".csync_journal.db.ctemporary") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal ("subdir/.csync_journal.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal ("/two/subdir/.csync_journal.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  /* also the new form of the database name */
        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db.ctemporary") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db-shm") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal ("subdir/.sync_5bdd60bdfcfa.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db.ctemporary") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal (".sync_5bdd60bdfcfa.db-shm") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal ("subdir/.sync_5bdd60bdfcfa.db") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  /* Other builtin excludes */
        //  GLib.assert_true (check_file_traversal ("foo/Desktop.ini") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_traversal ("Desktop.ini") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  /* pattern ]*.directory - ignore and remove */
        //  GLib.assert_true (check_file_traversal ("my.~directory") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE);
        //  GLib.assert_true (check_file_traversal ("/a_folder/my.~directory") == CSync.CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE);

        //  /* Not excluded because the pattern .netscape/cache requires directory. */
        //  GLib.assert_true (check_file_traversal (".netscape/cache") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* Not excluded  */
        //  GLib.assert_true (check_file_traversal ("unicode/中文.hé") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  /* excluded  */
        //  GLib.assert_true (check_file_traversal ("unicode/пятницы.txt") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("unicode/中文.💩") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  /* path wildcards */
        //  GLib.assert_true (check_file_traversal ("foobar/my_manuscript.out") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("latex_temporary/my_manuscript.run.xml") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("word_temporary/my_manuscript.run.xml") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("latex/my_manuscript.tex.temporary") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("latex/songbook/my_manuscript.tex.temporary") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  /* From here the actual traversal tests */

        //  excluded_files.add_manual_exclude ("/exclude");
        //  excluded_files.reload_exclude_files ();

        //  /* Check toplevel directory, the pattern only works for toplevel directory. */
        //  GLib.assert_true (check_dir_traversal ("/exclude") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_traversal ("/foo/exclude") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* check for a file called exclude. Must still work */
        //  GLib.assert_true (check_file_traversal ("/exclude") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("/foo/exclude") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* Add an exclude for directories only : excl/ */
        //  excluded_files.add_manual_exclude ("excl/");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_dir_traversal ("/excl") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_traversal ("meep/excl") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  // because leading dirs aren't checked!
        //  GLib.assert_true (check_file_traversal ("meep/excl/file") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("/excl") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  excluded_files.add_manual_exclude ("/excludepath/withsubdir");
        //  excluded_files.reload_exclude_files ();

        //  GLib.assert_true (check_dir_traversal ("/excludepath/withsubdir") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("/excludepath/withsubdir") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_traversal ("/excludepath/withsubdir2") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  // because leading dirs aren't checked!
        //  GLib.assert_true (check_dir_traversal ("/excludepath/withsubdir/foo") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* Check ending of pattern */
        //  GLib.assert_true (check_file_traversal ("/exclude") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("/exclude_x") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("exclude") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  excluded_files.add_manual_exclude ("exclude");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_traversal ("exclude") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  /* ? character */
        //  excluded_files.add_manual_exclude ("bond00?");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_traversal ("bond00") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("bond007") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("bond0071") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* brackets */
        //  excluded_files.add_manual_exclude ("a [bc] d");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_traversal ("a d d") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("a  d") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("a b d") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("a c d") == CSync.CSync.ExcludedFiles.Type.LIST);

        //  /* escapes */
        //  excluded_files.add_manual_exclude ("a \\*");
        //  excluded_files.add_manual_exclude ("b \\?");
        //  excluded_files.add_manual_exclude ("c \\[d]");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_traversal ("a \\*") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("a bc") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("a *") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("b \\?") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("b f") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("b ?") == CSync.CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_traversal ("c \\[d]") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("c d") == CSync.CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_traversal ("c [d]") == CSync.CSync.ExcludedFiles.Type.LIST);
    }

} // class TestCSyncExcludedTraversal

} // namespace Testing
} // namespace Occ
