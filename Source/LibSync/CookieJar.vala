/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFile>
// #include <QDateTime>
// #include <QLoggingCategory>
// #include <QNetworkCookie>
// #include <QDataStream>
// #include <QDir>

// #include <QNetworkCookieJar>

namespace Occ {

/***********************************************************
@brief The CookieJar class
@ingroup libsync
***********************************************************/
class CookieJar : QNetworkCookieJar {
public:
    CookieJar (GLib.Object *parent = nullptr);
    ~CookieJar () override;
    bool set_cookies_from_url (QList<QNetworkCookie> &cookie_list, QUrl &url) override;
    QList<QNetworkCookie> cookies_for_url (QUrl &url) const override;

    void clear_session_cookies ();

    using QNetworkCookieJar.set_all_cookies;
    using QNetworkCookieJar.all_cookies;

    bool save (string &file_name);
    bool restore (string &file_name);

signals:
    void new_cookies_for_url (QList<QNetworkCookie> &cookie_list, QUrl &url);

private:
    QList<QNetworkCookie> remove_expired (QList<QNetworkCookie> &cookies);
};


    namespace {
        const unsigned int JAR_VERSION = 23;
    }

    QDataStream &operator<< (QDataStream &stream, QList<QNetworkCookie> &list) {
        stream << JAR_VERSION;
        stream << uint32 (list.size ());
        for (auto &cookie : list)
            stream << cookie.to_raw_form ();
        return stream;
    }

    QDataStream &operator>> (QDataStream &stream, QList<QNetworkCookie> &list) {
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
            QList<QNetworkCookie> new_cookies = QNetworkCookie.parse_cookies (value);
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
        : QNetworkCookieJar (parent) {
    }

    CookieJar.~CookieJar () = default;

    bool CookieJar.set_cookies_from_url (QList<QNetworkCookie> &cookie_list, QUrl &url) {
        if (QNetworkCookieJar.set_cookies_from_url (cookie_list, url)) {
            Q_EMIT new_cookies_for_url (cookie_list, url);
            return true;
        }

        return false;
    }

    QList<QNetworkCookie> CookieJar.cookies_for_url (QUrl &url) {
        QList<QNetworkCookie> cookies = QNetworkCookieJar.cookies_for_url (url);
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
        QDataStream stream (&file);
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
        if (!file.open (QIODevice.ReadOnly)) {
            return false;
        }
        QDataStream stream (&file);
        QList<QNetworkCookie> list;
        stream >> list;
        set_all_cookies (remove_expired (list));
        file.close ();
        return true;
    }

    QList<QNetworkCookie> CookieJar.remove_expired (QList<QNetworkCookie> &cookies) {
        QList<QNetworkCookie> updated_list;
        foreach (QNetworkCookie &cookie, cookies) {
            if (cookie.expiration_date () > QDateTime.current_date_time_utc () && !cookie.is_session_cookie ()) {
                updated_list << cookie;
            }
        }
        return updated_list;
    }

    } // namespace Occ
    