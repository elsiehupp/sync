/***********************************************************
Copyright (C) by Camila Ayres <hello@camila.codes>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QByteArray>
// #include <QNetworkAccessManager>
// #include <QNetworkRequest>
// #include <QNetworkReply>

namespace Occ {

/***********************************************************
@brief Job to fetch a icon
@ingroup gui
***********************************************************/
class IconJob : GLib.Object {
public:
    IconJob (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);

signals:
    void jobFinished (QByteArray iconData);
    void error (QNetworkReply.NetworkError errorType);

private slots:
    void finished ();
};
}
