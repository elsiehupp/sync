/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
Represents a conflict in the conflicts table.

In the following the "conflict file" is the file that has
the conflict tag in the filename, and the base file is the
file that it's a conflict for. So if "a/foo.txt" is the
base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".
***********************************************************/
class ConflictRecord {

    /***********************************************************
    Path to the file with the conflict tag in the name

    The path is sync-folder relative.
    ***********************************************************/
    public GLib.ByteArray path;


    /***********************************************************
    File identifier of the base file
    ***********************************************************/
    public GLib.ByteArray base_file_id;


    /***********************************************************
    Modtime of the base file

    may not be available and be -1
    ***********************************************************/
    public int64 base_modtime = -1;


    /***********************************************************
    Etag of the base file

    may not be available and empty
    ***********************************************************/
    public GLib.ByteArray base_etag;


    /***********************************************************
    The path of the original file at the time the conflict was created

    Note that in nearly all cases one should query
    thus retrieve the current* base path instead!

    maybe be empty if not available
    ***********************************************************/
    public GLib.ByteArray initial_base_path;

    /***********************************************************
    ***********************************************************/
    public bool is_valid () {
        return !path.is_empty ();
    }

} // class ConflictRecord

} // namespace Occ
