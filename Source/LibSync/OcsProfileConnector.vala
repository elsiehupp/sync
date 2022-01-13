#pragma once

// #include <GLib.Object>
// #include <QPixmap>
// #include <QUrl>
// #include <string>
// #include <QJsonObject>
// #include <QJsonDocument>
// #include <QJsonArray>
// #include <QLoggingCategory>
// #include <QIcon>
// #include <QPainter>
// #include <QImage>
// #include <QSvgRenderer>
// #include <QNetworkReply>
// #include <QPixmap>
// #include <QPixmapCache>

namespace Occ {


struct HovercardAction {
public:
    HovercardAction ();
    HovercardAction (string title, QUrl iconUrl, QUrl link);

    string _title;
    QUrl _iconUrl;
    QPixmap _icon;
    QUrl _link;
};

struct Hovercard {
    std.vector<HovercardAction> _actions;
};

class OcsProfileConnector : GLib.Object {
public:
    OcsProfileConnector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetchHovercard (string &userId);
    const Hovercard &hovercard ();

signals:
    void error ();
    void hovercardFetched ();
    void iconLoaded (std.size_t hovercardActionIndex);

private:
    void onHovercardFetched (QJsonDocument &json, int statusCode);

    void fetchIcons ();
    void startFetchIconJob (std.size_t hovercardActionIndex);
    void setHovercardActionIcon (std.size_t index, QPixmap &pixmap);
    void loadHovercardActionIcon (std.size_t hovercardActionIndex, QByteArray &iconData);

    AccountPtr _account;
    Hovercard _currentHovercard;
};




    Occ.HovercardAction jsonToAction (QJsonObject &jsonActionObject) {
        const auto iconUrl = jsonActionObject.value (QStringLiteral ("icon")).toString (QStringLiteral ("no-icon"));
        QPixmap iconPixmap;
        Occ.HovercardAction hovercardAction{
            jsonActionObject.value (QStringLiteral ("title")).toString (QStringLiteral ("No title")), iconUrl,
            jsonActionObject.value (QStringLiteral ("hyperlink")).toString (QStringLiteral ("no-link"))};
        if (QPixmapCache.find (iconUrl, &iconPixmap)) {
            hovercardAction._icon = iconPixmap;
        }
        return hovercardAction;
    }
    
    Occ.Hovercard jsonToHovercard (QJsonArray &jsonDataArray) {
        Occ.Hovercard hovercard;
        hovercard._actions.reserve (jsonDataArray.size ());
        for (auto &jsonEntry : jsonDataArray) {
            Q_ASSERT (jsonEntry.isObject ());
            if (!jsonEntry.isObject ()) {
                continue;
            }
            hovercard._actions.push_back (jsonToAction (jsonEntry.toObject ()));
        }
        return hovercard;
    }
    
    Occ.Optional<QPixmap> createPixmapFromSvgData (QByteArray &iconData) {
        QSvgRenderer svgRenderer;
        if (!svgRenderer.load (iconData)) {
            return {};
        }
        QSize imageSize{16, 16};
        if (Occ.Theme.isHidpi ()) {
            imageSize = QSize{32, 32};
        }
        QImage scaledSvg (imageSize, QImage.Format_ARGB32);
        scaledSvg.fill ("transparent");
        QPainter svgPainter{&scaledSvg};
        svgRenderer.render (&svgPainter);
        return QPixmap.fromImage (scaledSvg);
    }
    
    Occ.Optional<QPixmap> iconDataToPixmap (QByteArray iconData) {
        if (!iconData.startsWith ("<svg")) {
            return {};
        }
        return createPixmapFromSvgData (iconData);
    }
    
    HovercardAction.HovercardAction () = default;
    
    HovercardAction.HovercardAction (string title, QUrl iconUrl, QUrl link)
        : _title (std.move (title))
        , _iconUrl (std.move (iconUrl))
        , _link (std.move (link)) {
    }
    
    OcsProfileConnector.OcsProfileConnector (AccountPtr account, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account) {
    }
    
    void OcsProfileConnector.fetchHovercard (string &userId) {
        if (_account.serverVersionInt () < Account.makeServerVersion (23, 0, 0)) {
            qInfo (lcOcsProfileConnector) << "Server version" << _account.serverVersion ()
                                         << "does not support profile page";
            emit error ();
            return;
        }
        const string url = QStringLiteral ("/ocs/v2.php/hovercard/v1/%1").arg (userId);
        const auto job = new JsonApiJob (_account, url, this);
        connect (job, &JsonApiJob.jsonReceived, this, &OcsProfileConnector.onHovercardFetched);
        job.start ();
    }
    
    void OcsProfileConnector.onHovercardFetched (QJsonDocument &json, int statusCode) {
        qCDebug (lcOcsProfileConnector) << "Hovercard fetched:" << json;
    
        if (statusCode != 200) {
            qCInfo (lcOcsProfileConnector) << "Fetching of hovercard finished with status code" << statusCode;
            return;
        }
        const auto jsonData = json.object ().value ("ocs").toObject ().value ("data").toObject ().value ("actions");
        Q_ASSERT (jsonData.isArray ());
        _currentHovercard = jsonToHovercard (jsonData.toArray ());
        fetchIcons ();
        emit hovercardFetched ();
    }
    
    void OcsProfileConnector.setHovercardActionIcon (std.size_t index, QPixmap &pixmap) {
        auto &hovercardAction = _currentHovercard._actions[index];
        QPixmapCache.insert (hovercardAction._iconUrl.toString (), pixmap);
        hovercardAction._icon = pixmap;
        emit iconLoaded (index);
    }
    
    void OcsProfileConnector.loadHovercardActionIcon (std.size_t hovercardActionIndex, QByteArray &iconData) {
        if (hovercardActionIndex >= _currentHovercard._actions.size ()) {
            // Note : Probably could do more checking, like checking if the url is still the same.
            return;
        }
        const auto icon = iconDataToPixmap (iconData);
        if (icon.isValid ()) {
            setHovercardActionIcon (hovercardActionIndex, icon.get ());
            return;
        }
        qCWarning (lcOcsProfileConnector) << "Could not load Svg icon from data" << iconData;
    }
    
    void OcsProfileConnector.startFetchIconJob (std.size_t hovercardActionIndex) {
        const auto hovercardAction = _currentHovercard._actions[hovercardActionIndex];
        const auto iconJob = new IconJob{_account, hovercardAction._iconUrl, this};
        connect (iconJob, &IconJob.jobFinished,
            [this, hovercardActionIndex] (QByteArray iconData) { loadHovercardActionIcon (hovercardActionIndex, iconData); });
        connect (iconJob, &IconJob.error, this, [] (QNetworkReply.NetworkError errorType) {
            qCWarning (lcOcsProfileConnector) << "Could not fetch icon:" << errorType;
        });
    }
    
    void OcsProfileConnector.fetchIcons () {
        for (auto hovercardActionIndex = 0u; hovercardActionIndex < _currentHovercard._actions.size ();
             ++hovercardActionIndex) {
            startFetchIconJob (hovercardActionIndex);
        }
    }
    
    const Hovercard &OcsProfileConnector.hovercard () {
        return _currentHovercard;
    }
    }
    