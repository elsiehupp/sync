/*
 * Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QNetworkCookieJar>

namespace OCC {

/**
 * @brief The CookieJar class
 * @ingroup libsync
 */
class OWNCLOUDSYNC_EXPORT CookieJar : public QNetworkCookieJar {
public:
    explicit CookieJar(QObject *parent = nullptr);
    ~CookieJar() override;
    bool setCookiesFromUrl(QList<QNetworkCookie> &cookieList, QUrl &url) override;
    QList<QNetworkCookie> cookiesForUrl(QUrl &url) const override;

    void clearSessionCookies();

    using QNetworkCookieJar::setAllCookies;
    using QNetworkCookieJar::allCookies;

    bool save(QString &fileName);
    bool restore(QString &fileName);

signals:
    void newCookiesForUrl(QList<QNetworkCookie> &cookieList, QUrl &url);

private:
    QList<QNetworkCookie> removeExpired(QList<QNetworkCookie> &cookies);
};

} // namespace OCC

#endif // MIRALL_COOKIEJAR_H
