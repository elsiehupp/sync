namespace Occ {
namespace Common {

/***********************************************************
@class ConflictRecord

@brief Represents a conflict in the conflicts table.

@details In the following the "conflict file" is the file
that has the conflict tag in the filename, and the base file
is the file that it's a conflict for. So if "a/foo.txt" is
the base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".

@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class ConflictRecord { //: GLib.Object {

//    /***********************************************************
//    Path to the file with the conflict tag in the name

//    The path is sync-folder relative.
//    ***********************************************************/
//    public string path;


//    /***********************************************************
//    File identifier of the base file
//    ***********************************************************/
//    public string base_file_id;


//    /***********************************************************
//    Modtime of the base file

//    may not be available and be -1
//    ***********************************************************/
//    public int64 base_modtime = -1;


//    /***********************************************************
//    Etag of the base file

//    may not be available and empty
//    ***********************************************************/
//    public string base_etag;


//    /***********************************************************
//    The path of the original file at the time the conflict was created

//    Note that in nearly all cases one should query
//    thus retrieve the current* base path instead!

//    maybe be empty if not available
//    ***********************************************************/
//    public string initial_base_path;

//    /***********************************************************
//    ***********************************************************/
//    public bool is_valid {
//        public get {
//            return path != "";
//        }
//    }

} // class ConflictRecord

} // namespace Common
} // namespace Occ
