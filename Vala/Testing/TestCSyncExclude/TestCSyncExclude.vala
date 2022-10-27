namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExclude

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExclude : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExclude () {
        //  base ();
        //  GLib.assert_true (check_file_full ("") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("/") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("A") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("krawel_krawel") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full (".kde/share/config/kwin.eventsrc") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full (".directory/cache-maximegalon/cache1.txt") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_full ("mozilla/.directory") == CSync.ExcludedFiles.Type.LIST);


        //  /***********************************************************
        //  Test for patterns in subdirectories. '.beagle' is defined
        //  as a pattern and has to be found in top directory as well as
        //  in directories underneath.
        //  ***********************************************************/
        //  GLib.assert_true (check_dir_full (".apdisk") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_full ("foo/.apdisk") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_dir_full ("foo/bar/.apdisk") == CSync.ExcludedFiles.Type.LIST);

        //  GLib.assert_true (check_file_full (".java") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* Files in the ignored directory .java will also be ignored. */
        //  GLib.assert_true (check_file_full (".apdisk/totally_amazing.jar") == CSync.ExcludedFiles.Type.LIST);

        //  /* and also in subdirectories */
        //  GLib.assert_true (check_file_full ("projects/.apdisk/totally_amazing.jar") == CSync.ExcludedFiles.Type.LIST);

        //  /* csync-journal is ignored in general silently. */
        //  GLib.assert_true (check_file_full (".csync_journal.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full (".csync_journal.db.ctemporary") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full ("subdir/.csync_journal.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  /* also the new form of the database name */
        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db.ctemporary") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db-shm") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full ("subdir/.sync_5bdd60bdfcfa.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db.ctemporary") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full (".sync_5bdd60bdfcfa.db-shm") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);
        //  GLib.assert_true (check_file_full ("subdir/.sync_5bdd60bdfcfa.db") == CSync.ExcludedFiles.Type.EXCLUDE_SILENT);

        //  /* pattern ]*.directory - ignore and remove */
        //  GLib.assert_true (check_file_full ("my.~directory") == CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE);
        //  GLib.assert_true (check_file_full ("/a_folder/my.~directory") == CSync.ExcludedFiles.Type.EXCLUDE_AND_REMOVE);

        //  /* Not excluded because the pattern .netscape/cache requires directory. */
        //  GLib.assert_true (check_file_full (".netscape/cache") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* Not excluded  */
        //  GLib.assert_true (check_file_full ("unicode/中文.hé") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  /* excluded  */
        //  GLib.assert_true (check_file_full ("unicode/пятницы.txt") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("unicode/中文.💩") == CSync.ExcludedFiles.Type.LIST);

        //  /* path wildcards */
        //  GLib.assert_true (check_file_full ("foobar/my_manuscript.out") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("latex_temporary/my_manuscript.run.xml") == CSync.ExcludedFiles.Type.LIST);

        //  GLib.assert_true (check_file_full ("word_temporary/my_manuscript.run.xml") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  GLib.assert_true (check_file_full ("latex/my_manuscript.tex.temporary") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  GLib.assert_true (check_file_full ("latex/songbook/my_manuscript.tex.temporary") == CSync.ExcludedFiles.Type.LIST);

        //  /* ? character */
        //  excluded_files.add_manual_exclude ("bond00?");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_full ("bond00") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("bond007") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("bond0071") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);

        //  /* brackets */
        //  excluded_files.add_manual_exclude ("a [bc] d");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_full ("a d d") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("a  d") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("a b d") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("a c d") == CSync.ExcludedFiles.Type.LIST);

        //  /* escapes */
        //  excluded_files.add_manual_exclude ("a \\*");
        //  excluded_files.add_manual_exclude ("b \\?");
        //  excluded_files.add_manual_exclude ("c \\[d]");
        //  excluded_files.reload_exclude_files ();
        //  GLib.assert_true (check_file_full ("a \\*") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("a bc") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("a *") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("b \\?") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("b f") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("b ?") == CSync.ExcludedFiles.Type.LIST);
        //  GLib.assert_true (check_file_full ("c \\[d]") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("c d") == CSync.ExcludedFiles.Type.NOT_EXCLUDED);
        //  GLib.assert_true (check_file_full ("c [d]") == CSync.ExcludedFiles.Type.LIST);
    }

} // class TestCSyncExclude

} // namespace Testing
} // namespace Occ
