/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QNetworkCookie>
//  #include <QDataStream>
//  #include <QDir>
//  #include
//  #include <QNetworkCookieJar>

namespace Occ {

using QNetworkCookieJar.set_all_cookies;
using QNetworkCookieJar.all_cookies;

/***********************************************************
@brief The CookieJar class
@ingroup libsync
***********************************************************/
class CookieJar : QNetworkCookieJar {

    const uint32 JAR_VERSION = 23;

    /***********************************************************
    ***********************************************************/
    signal void new_cookies_for_url (GLib.List<QNetworkCookie> cookie_list, GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public CookieJar (GLib.Object parent = new GLib.Object ())
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    ~CookieJar () = default;


    /***********************************************************
    ***********************************************************/
    public bool set_cookies_from_url (GLib.List<QNetworkCookie> cookie_list, GLib.Uri url) {
        if (QNetworkCookieJar.set_cookies_from_url (cookie_list, url)) {
            /* Q_EMIT */ new_cookies_for_url (cookie_list, url);
            return true;
        }

        return false;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<QNetworkCookie> cookies_for_url (GLib.Uri url) {
        GLib.List<QNetworkCookie> cookies = QNetworkCookieJar.cookies_for_url (url);
        GLib.debug (lc_cookie_jar) << url << "requests:" << cookies;
        return cookies;
    }


    /***********************************************************
    ***********************************************************/
    public void clear_session_cookies () {
        set_all_cookies (remove_expired (all_cookies ()));
    }


    /***********************************************************
    ***********************************************************/
    public bool save (string filename) {
        const QFileInfo info (filename);
        if (!info.dir ().exists ()) {
            info.dir ().mkpath (".");
        }

        GLib.debug (lc_cookie_jar) << filename;
        GLib.File file = new GLib.File (filename);
        if (!file.open (QIODevice.WriteOnly)) {
            return false;
        }
        QDataStream stream (&file);
        stream << remove_expired (all_cookies ());
        file.close ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool restore (string filename) {
        const QFileInfo info (filename);
        if (!info.exists ()) {
            return false;
        }

        GLib.File file = new GLib.File (filename);
        if (!file.open (QIODevice.ReadOnly)) {
            return false;
        }
        QDataStream stream (&file);
        GLib.List<QNetworkCookie> list;
        stream >> list;
        set_all_cookies (remove_expired (list));
        file.close ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private GLib.List<QNetworkCookie> remove_expired (GLib.List<QNetworkCookie> cookies) {
        GLib.List<QNetworkCookie> updated_list;
        foreach (QNetworkCookie cookie, cookies) {
            if (cookie.expiration_date () > GLib.DateTime.current_date_time_utc () && !cookie.is_session_cookie ()) {
                updated_list << cookie;
            }
        }
        return updated_list;
    }


    //  QDataStream operator<< (QDataStream stream, GLib.List<QNetworkCookie> list) {
    //      stream << JAR_VERSION;
    //      stream << uint32 (list.size ());
    //      for (var cookie : list)
    //          stream << cookie.to_raw_form ();
    //      return stream;
    //  }


    //  QDataStream operator>> (QDataStream stream, GLib.List<QNetworkCookie> list) {
    //      list.clear ();

    //      uint32 version = 0;
    //      stream >> version;

    //      if (version != JAR_VERSION)
    //          return stream;

    //      uint32 count = 0;
    //      stream >> count;
    //      for (uint32 i = 0; i < count; ++i) {
    //          GLib.ByteArray value;
    //          stream >> value;
    //          GLib.List<QNetworkCookie> new_cookies = QNetworkCookie.parse_cookies (value);
    //          if (new_cookies.count () == 0 && value.length () != 0) {
    //              GLib.warn (lc_cookie_jar) << "CookieJar : Unable to parse saved cookie:" << value;
    //          }
    //          for (int j = 0; j < new_cookies.count (); ++j)
    //              list.append (new_cookies.at (j));
    //          if (stream.at_end ())
    //              break;
    //      }
    //      return stream;
    //  }

} // class CookieJar

} // namespace Occ
    