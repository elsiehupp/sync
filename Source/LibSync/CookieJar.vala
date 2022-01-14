/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QDateTime>
// #include <QLoggingCategory>
// #include <QNetwork_cookie>
// #include <QData_stream>
// #include <QDir>

// #include <QNetwork_cookie_jar>

namespace Occ {

/***********************************************************
@brief The CookieJar class
@ingroup libsync
***********************************************************/
class CookieJar : QNetwork_cookie_jar {
public:
    CookieJar (GLib.Object *parent = nullptr);
    ~CookieJar () override;
    bool set_cookies_from_url (QList<QNetwork_cookie> &cookie_list, QUrl &url) override;
    QList<QNetwork_cookie> cookies_for_url (QUrl &url) const override;

    void clear_session_cookies ();

    using QNetwork_cookie_jar.set_all_cookies;
    using QNetwork_cookie_jar.all_cookies;

    bool save (string &file_name);
    bool restore (string &file_name);

signals:
    void new_cookies_for_url (QList<QNetwork_cookie> &cookie_list, QUrl &url);

private:
    QList<QNetwork_cookie> remove_expired (QList<QNetwork_cookie> &cookies);
};


    namespace {
        const unsigned int JAR_VERSION = 23;
    }
    
    QData_stream &operator<< (QData_stream &stream, QList<QNetwork_cookie> &list) {
        stream << JAR_VERSION;
        stream << uint32 (list.size ());
        for (auto &cookie : list)
            stream << cookie.to_raw_form ();
        return stream;
    }
    
    QData_stream &operator>> (QData_stream &stream, QList<QNetwork_cookie> &list) {
        list.clear ();
    
        uint32 version = 0;
        stream >> version;
    
        if (version != JAR_VERSION)
            return stream;
    
        uint32 count = 0;
        stream >> count;
        for (uint32 i = 0; i < count; ++i) {
            QByteArray value;
            stream >> value;
            QList<QNetwork_cookie> new_cookies = QNetwork_cookie.parse_cookies (value);
            if (new_cookies.count () == 0 && value.length () != 0) {
                q_c_warning (lc_cookie_jar) << "CookieJar : Unable to parse saved cookie:" << value;
            }
            for (int j = 0; j < new_cookies.count (); ++j)
                list.append (new_cookies.at (j));
            if (stream.at_end ())
                break;
        }
        return stream;
    }
    
    CookieJar.CookieJar (GLib.Object *parent)
        : QNetwork_cookie_jar (parent) {
    }
    
    CookieJar.~CookieJar () = default;
    
    bool CookieJar.set_cookies_from_url (QList<QNetwork_cookie> &cookie_list, QUrl &url) {
        if (QNetwork_cookie_jar.set_cookies_from_url (cookie_list, url)) {
            Q_EMIT new_cookies_for_url (cookie_list, url);
            return true;
        }
    
        return false;
    }
    
    QList<QNetwork_cookie> CookieJar.cookies_for_url (QUrl &url) {
        QList<QNetwork_cookie> cookies = QNetwork_cookie_jar.cookies_for_url (url);
        q_c_debug (lc_cookie_jar) << url << "requests:" << cookies;
        return cookies;
    }
    
    void CookieJar.clear_session_cookies () {
        set_all_cookies (remove_expired (all_cookies ()));
    }
    
    bool CookieJar.save (string &file_name) {
        const QFileInfo info (file_name);
        if (!info.dir ().exists ()) {
            info.dir ().mkpath (".");
        }
    
        q_c_debug (lc_cookie_jar) << file_name;
        QFile file (file_name);
        if (!file.open (QIODevice.WriteOnly)) {
            return false;
        }
        QData_stream stream (&file);
        stream << remove_expired (all_cookies ());
        file.close ();
        return true;
    }
    
    bool CookieJar.restore (string &file_name) {
        const QFileInfo info (file_name);
        if (!info.exists ()) {
            return false;
        }
    
        QFile file (file_name);
        if (!file.open (QIODevice.Read_only)) {
            return false;
        }
        QData_stream stream (&file);
        QList<QNetwork_cookie> list;
        stream >> list;
        set_all_cookies (remove_expired (list));
        file.close ();
        return true;
    }
    
    QList<QNetwork_cookie> CookieJar.remove_expired (QList<QNetwork_cookie> &cookies) {
        QList<QNetwork_cookie> updated_list;
        foreach (QNetwork_cookie &cookie, cookies) {
            if (cookie.expiration_date () > QDateTime.current_date_time_utc () && !cookie.is_session_cookie ()) {
                updated_list << cookie;
            }
        }
        return updated_list;
    }
    
    } // namespace Occ
    