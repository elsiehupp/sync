namespace Occ {
namespace LibSync {

/***********************************************************
@class EtagParser

@brief Strips quotes and gzip annotations

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class EtagParser { //: GLib.Object {

    public static string parse_etag (string header) {
        //  if (header == "") {
        //      return "";
        //  }
        //  string header_copy = header;

        //  // Weak E-Tags can appear when gzip compression is on, see #3946
        //  if (header_copy.has_prefix ("W/"))
        //      header_copy = header_copy.mid (2);

        //  // https://github.com/owncloud/client/issues/1195
        //  header_copy.replace ("-gzip", "");

        //  if (header_copy.length >= 2 && header_copy.has_prefix ("\") && header_copy.has_suffix ("\")) {
        //      header_copy = header_copy.mid (1, header_copy.length - 2);
        //  }
        //  return header_copy;
    }

} // class EtagParser

} // namespace LibSync
} // namespace Occ
