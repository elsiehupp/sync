namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagatorJobs

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagatorJobs : GLib.Object {

    /***********************************************************
    Tags for checksum header.
    It's here for being shared between Upload- and Download Job
    ***********************************************************/
    const string CHECK_SUM_HEADER_C = "OC-Checksum";
    const string CONTENT_MD5_HEADER_C = "Content-MD5";

    public static string local_file_id_from_full_id (string identifier) {
        return identifier.left (8);
    }

} // class PropagatorJobs

} // namespace LibSync
} //namespace Occ
    