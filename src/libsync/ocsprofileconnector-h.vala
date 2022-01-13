#pragma once

// #include <GLib.Object>
// #include <QPixmap>
// #include <QUrl>
// #include <QString>

namespace Occ {

struct OWNCLOUDSYNC_EXPORT HovercardAction {
public:
    HovercardAction ();
    HovercardAction (QString title, QUrl iconUrl, QUrl link);

    QString _title;
    QUrl _iconUrl;
    QPixmap _icon;
    QUrl _link;
};

struct OWNCLOUDSYNC_EXPORT Hovercard {
    std.vector<HovercardAction> _actions;
};

class OWNCLOUDSYNC_EXPORT OcsProfileConnector : GLib.Object {
public:
    OcsProfileConnector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetchHovercard (QString &userId);
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
}

Q_DECLARE_METATYPE (Occ.HovercardAction)
Q_DECLARE_METATYPE (Occ.Hovercard)
