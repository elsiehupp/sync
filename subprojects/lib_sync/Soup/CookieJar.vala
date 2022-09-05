namespace Occ {
namespace LibSync {

/***********************************************************
@brief The CookieJar class

@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class CookieJar { //: Soup.CookieJar {

    //  const uint32 JAR_VERSION = 23;

    //  /***********************************************************
    //  ***********************************************************/
    //  internal signal void signal_new_cookies_for_url (GLib.List<Soup.Cookie> cookie_list, GLib.Uri url);

    //  /***********************************************************
    //  ***********************************************************/
    //  public CookieJar (GLib.Object parent = new GLib.Object ()) {
    //      base (parent);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool cookies_from_url (GLib.List<Soup.Cookie> cookie_list, GLib.Uri url) {
    //      if (Soup.CookieJar.cookies_from_url (cookie_list, url)) {
    //          signal_new_cookies_for_url (cookie_list, url);
    //          return true;
    //      }

    //      return false;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.List<Soup.Cookie> cookies_for_url (GLib.Uri url) {
    //      GLib.List<Soup.Cookie> cookies = Soup.CookieJar.cookies_for_url (url);
    //      GLib.debug (url + " requests: " + cookies);
    //      return cookies;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void clear_session_cookies () {
    //      all_cookies (remove_expired (all_cookies ()));
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool save (string filename) {
    //      GLib.FileInfo info = GLib.File.new_for_path (filename);
    //      if (!info.directory ().exists ()) {
    //          info.directory ().mkpath (".");
    //      }

    //      GLib.debug (filename);
    //      GLib.File file = GLib.File.new_for_path (filename);
    //      if (!file.open (GLib.IODevice.WriteOnly)) {
    //          return false;
    //      }
    //      GLib.DataStream stream = new GLib.DataStream (file);
    //      stream += remove_expired (all_cookies ());
    //      file.close ();
    //      return true;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool restore (string filename) {
    //      GLib.FileInfo info = GLib.File.new_for_path (filename);
    //      if (!info.exists ()) {
    //          return false;
    //      }

    //      GLib.File file = GLib.File.new_for_path (filename);
    //      if (!file.open (GLib.IODevice.ReadOnly)) {
    //          return false;
    //      }
    //      GLib.DataStream stream = new GLib.DataStream (file);
    //      GLib.List<Soup.Cookie> list;
    //      stream >> list;
    //      all_cookies (remove_expired (list));
    //      file.close ();
    //      return true;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.List<Soup.Cookie> remove_expired (GLib.List<Soup.Cookie> cookies) {
    //      GLib.List<Soup.Cookie> updated_list;
    //      foreach (Soup.Cookie cookie in cookies) {
    //          if (cookie.expiration_date () > GLib.DateTime.current_date_time_utc () && !cookie.is_session_cookie ()) {
    //              updated_list += cookie;
    //          }
    //      }
    //      return updated_list;
    //  }


    //  //  GLib.DataStream operator<< (GLib.DataStream stream, GLib.List<Soup.Cookie> list) {
    //  //      stream + JAR_VERSION;
    //  //      stream + uint32 (list.size ());
    //  //      foreach (var cookie in list)
    //  //          stream + cookie.to_raw_form ();
    //  //      return stream;
    //  //  }


    //  //  GLib.DataStream operator>> (GLib.DataStream stream, GLib.List<Soup.Cookie> list) {
    //  //      list = "";

    //  //      uint32 version = 0;
    //  //      stream >> version;

    //  //      if (version != JAR_VERSION)
    //  //          return stream;

    //  //      uint32 count = 0;
    //  //      stream >> count;
    //  //      for (uint32 i = 0; i < count; ++i) {
    //  //          string value;
    //  //          stream >> value;
    //  //          GLib.List<Soup.Cookie> new_cookies = Soup.Cookie.parse_cookies (value);
    //  //          if (new_cookies.length == 0 && value.length != 0) {
    //  //              GLib.warning ("CookieJar : Unable to parse saved cookie:" + value;
    //  //          }
    //  //          for (int j = 0; j < new_cookies.length; ++j)
    //  //              list.append (new_cookies.at (j));
    //  //          if (stream.at_end ())
    //  //              break;
    //  //      }
    //  //      return stream;
    //  //  }

} // class CookieJar

} // namespace LibSync
} // namespace Occ
    //  