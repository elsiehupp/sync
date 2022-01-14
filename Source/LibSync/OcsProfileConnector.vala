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
// #include <QSvg_renderer>
// #include <QNetworkReply>
// #include <QPixmap>
// #include <QPixmap_cache>

namespace Occ {


struct Hovercard_action {
public:
    Hovercard_action ();
    Hovercard_action (string title, QUrl icon_url, QUrl link);

    string _title;
    QUrl _icon_url;
    QPixmap _icon;
    QUrl _link;
};

struct Hovercard {
    std.vector<Hovercard_action> _actions;
};

class Ocs_profile_connector : GLib.Object {
public:
    Ocs_profile_connector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetch_hovercard (string &user_id);
    const Hovercard &hovercard ();

signals:
    void error ();
    void hovercard_fetched ();
    void icon_loaded (std.size_t hovercard_action_index);

private:
    void on_hovercard_fetched (QJsonDocument &json, int status_code);

    void fetch_icons ();
    void start_fetch_icon_job (std.size_t hovercard_action_index);
    void set_hovercard_action_icon (std.size_t index, QPixmap &pixmap);
    void load_hovercard_action_icon (std.size_t hovercard_action_index, QByteArray &icon_data);

    AccountPtr _account;
    Hovercard _current_hovercard;
};




    Occ.Hovercard_action json_to_action (QJsonObject &json_action_object) {
        const auto icon_url = json_action_object.value (QStringLiteral ("icon")).to_string (QStringLiteral ("no-icon"));
        QPixmap icon_pixmap;
        Occ.Hovercard_action hovercard_action{
            json_action_object.value (QStringLiteral ("title")).to_string (QStringLiteral ("No title")), icon_url,
            json_action_object.value (QStringLiteral ("hyperlink")).to_string (QStringLiteral ("no-link"))};
        if (QPixmap_cache.find (icon_url, &icon_pixmap)) {
            hovercard_action._icon = icon_pixmap;
        }
        return hovercard_action;
    }

    Occ.Hovercard json_to_hovercard (QJsonArray &json_data_array) {
        Occ.Hovercard hovercard;
        hovercard._actions.reserve (json_data_array.size ());
        for (auto &json_entry : json_data_array) {
            Q_ASSERT (json_entry.is_object ());
            if (!json_entry.is_object ()) {
                continue;
            }
            hovercard._actions.push_back (json_to_action (json_entry.to_object ()));
        }
        return hovercard;
    }

    Occ.Optional<QPixmap> create_pixmap_from_svg_data (QByteArray &icon_data) {
        QSvg_renderer svg_renderer;
        if (!svg_renderer.load (icon_data)) {
            return {};
        }
        QSize image_size{16, 16};
        if (Occ.Theme.is_hidpi ()) {
            image_size = QSize{32, 32};
        }
        QImage scaled_svg (image_size, QImage.Format_ARGB32);
        scaled_svg.fill ("transparent");
        QPainter svg_painter{&scaled_svg};
        svg_renderer.render (&svg_painter);
        return QPixmap.from_image (scaled_svg);
    }

    Occ.Optional<QPixmap> icon_data_to_pixmap (QByteArray icon_data) {
        if (!icon_data.starts_with ("<svg")) {
            return {};
        }
        return create_pixmap_from_svg_data (icon_data);
    }

    Hovercard_action.Hovercard_action () = default;

    Hovercard_action.Hovercard_action (string title, QUrl icon_url, QUrl link)
        : _title (std.move (title))
        , _icon_url (std.move (icon_url))
        , _link (std.move (link)) {
    }

    Ocs_profile_connector.Ocs_profile_connector (AccountPtr account, GLib.Object *parent)
        : GLib.Object (parent)
        , _account (account) {
    }

    void Ocs_profile_connector.fetch_hovercard (string &user_id) {
        if (_account.server_version_int () < Account.make_server_version (23, 0, 0)) {
            q_info (lc_ocs_profile_connector) << "Server version" << _account.server_version ()
                                         << "does not support profile page";
            emit error ();
            return;
        }
        const string url = QStringLiteral ("/ocs/v2.php/hovercard/v1/%1").arg (user_id);
        const auto job = new JsonApiJob (_account, url, this);
        connect (job, &JsonApiJob.json_received, this, &Ocs_profile_connector.on_hovercard_fetched);
        job.start ();
    }

    void Ocs_profile_connector.on_hovercard_fetched (QJsonDocument &json, int status_code) {
        q_c_debug (lc_ocs_profile_connector) << "Hovercard fetched:" << json;

        if (status_code != 200) {
            q_c_info (lc_ocs_profile_connector) << "Fetching of hovercard finished with status code" << status_code;
            return;
        }
        const auto json_data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("actions");
        Q_ASSERT (json_data.is_array ());
        _current_hovercard = json_to_hovercard (json_data.to_array ());
        fetch_icons ();
        emit hovercard_fetched ();
    }

    void Ocs_profile_connector.set_hovercard_action_icon (std.size_t index, QPixmap &pixmap) {
        auto &hovercard_action = _current_hovercard._actions[index];
        QPixmap_cache.insert (hovercard_action._icon_url.to_string (), pixmap);
        hovercard_action._icon = pixmap;
        emit icon_loaded (index);
    }

    void Ocs_profile_connector.load_hovercard_action_icon (std.size_t hovercard_action_index, QByteArray &icon_data) {
        if (hovercard_action_index >= _current_hovercard._actions.size ()) {
            // Note : Probably could do more checking, like checking if the url is still the same.
            return;
        }
        const auto icon = icon_data_to_pixmap (icon_data);
        if (icon.is_valid ()) {
            set_hovercard_action_icon (hovercard_action_index, icon.get ());
            return;
        }
        q_c_warning (lc_ocs_profile_connector) << "Could not load Svg icon from data" << icon_data;
    }

    void Ocs_profile_connector.start_fetch_icon_job (std.size_t hovercard_action_index) {
        const auto hovercard_action = _current_hovercard._actions[hovercard_action_index];
        const auto icon_job = new Icon_job{_account, hovercard_action._icon_url, this};
        connect (icon_job, &Icon_job.job_finished,
            [this, hovercard_action_index] (QByteArray icon_data) {
                load_hovercard_action_icon (hovercard_action_index, icon_data);
            });
        connect (icon_job, &Icon_job.error, this, [] (QNetworkReply.NetworkError error_type) {
            q_c_warning (lc_ocs_profile_connector) << "Could not fetch icon:" << error_type;
        });
    }

    void Ocs_profile_connector.fetch_icons () {
        for (auto hovercard_action_index = 0u; hovercard_action_index < _current_hovercard._actions.size ();
             ++hovercard_action_index) {
            start_fetch_icon_job (hovercard_action_index);
        }
    }

    const Hovercard &Ocs_profile_connector.hovercard () {
        return _current_hovercard;
    }
    }
    