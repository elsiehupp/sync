#pragma once

// #include <QPixmap>
// #include <GLib.Uri>
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

    /***********************************************************
    ***********************************************************/
    public HovercardAction ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public string this.title;
    public GLib.Uri this.icon_url;
    public QPixmap this.icon;
    public GLib.Uri this.link;
};

struct Hovercard {
    std.vector<HovercardAction> this.actions;
};

class OcsProfileConnector : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public OcsProfileConnector (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public void fetch_hovercard (string user_id);

    /***********************************************************
    ***********************************************************/
    public 
    public const Hovercard hovercard ();

signals:
    void error ();
    void hovercard_fetched ();
    void icon_loaded (std.size_t hovercard_action_index);


    /***********************************************************
    ***********************************************************/
    private void on_hovercard_fetched (QJsonDocument json, int status_code);

    /***********************************************************
    ***********************************************************/
    private void fetch_icons ();
    private void start_fetch_icon_job (std.size_t hovercard_action_index);
    private void set_hovercard_action_icon (std.size_t index, QPixmap pixmap);
    private void load_hovercard_action_icon (std.size_t hovercard_action_index, GLib.ByteArray icon_data);

    AccountPointer this.account;
    Hovercard this.current_hovercard;
};




    Occ.HovercardAction json_to_action (QJsonObject json_action_object) {
        const var icon_url = json_action_object.value (QStringLiteral ("icon")).to_string (QStringLiteral ("no-icon"));
        QPixmap icon_pixmap;
        Occ.HovercardAction hovercard_action{
            json_action_object.value (QStringLiteral ("title")).to_string (QStringLiteral ("No title")), icon_url,
            json_action_object.value (QStringLiteral ("hyperlink")).to_string (QStringLiteral ("no-link"))};
        if (QPixmapCache.find (icon_url, icon_pixmap)) {
            hovercard_action._icon = icon_pixmap;
        }
        return hovercard_action;
    }

    Occ.Hovercard json_to_hovercard (QJsonArray json_data_array) {
        Occ.Hovercard hovercard;
        hovercard._actions.reserve (json_data_array.size ());
        for (var json_entry : json_data_array) {
            Q_ASSERT (json_entry.is_object ());
            if (!json_entry.is_object ()) {
                continue;
            }
            hovercard._actions.push_back (json_to_action (json_entry.to_object ()));
        }
        return hovercard;
    }

    Occ.Optional<QPixmap> create_pixmap_from_svg_data (GLib.ByteArray icon_data) {
        QSvgRenderer svg_renderer;
        if (!svg_renderer.on_load (icon_data)) {
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

    Occ.Optional<QPixmap> icon_data_to_pixmap (GLib.ByteArray icon_data) {
        if (!icon_data.starts_with ("<svg")) {
            return {};
        }
        return create_pixmap_from_svg_data (icon_data);
    }

    HovercardAction.HovercardAction () = default;

    HovercardAction.HovercardAction (string title, GLib.Uri icon_url, GLib.Uri link)
        : this.title (std.move (title))
        , this.icon_url (std.move (icon_url))
        , this.link (std.move (link)) {
    }

    OcsProfileConnector.OcsProfileConnector (AccountPointer account, GLib.Object parent)
        : GLib.Object (parent)
        , this.account (account) {
    }

    void OcsProfileConnector.fetch_hovercard (string user_id) {
        if (this.account.server_version_int () < Account.make_server_version (23, 0, 0)) {
            q_info (lc_ocs_profile_connector) << "Server version" << this.account.server_version ()
                                         << "does not support profile page";
            /* emit */ error ();
            return;
        }
        const string url = QStringLiteral ("/ocs/v2.php/hovercard/v1/%1").arg (user_id);
        const var job = new JsonApiJob (this.account, url, this);
        connect (job, &JsonApiJob.json_received, this, &OcsProfileConnector.on_hovercard_fetched);
        job.on_start ();
    }

    void OcsProfileConnector.on_hovercard_fetched (QJsonDocument json, int status_code) {
        GLib.debug (lc_ocs_profile_connector) << "Hovercard fetched:" << json;

        if (status_code != 200) {
            q_c_info (lc_ocs_profile_connector) << "Fetching of hovercard on_finished with status code" << status_code;
            return;
        }
        const var json_data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("actions");
        Q_ASSERT (json_data.is_array ());
        this.current_hovercard = json_to_hovercard (json_data.to_array ());
        fetch_icons ();
        /* emit */ hovercard_fetched ();
    }

    void OcsProfileConnector.set_hovercard_action_icon (std.size_t index, QPixmap pixmap) {
        var hovercard_action = this.current_hovercard._actions[index];
        QPixmapCache.insert (hovercard_action._icon_url.to_"", pixmap);
        hovercard_action._icon = pixmap;
        /* emit */ icon_loaded (index);
    }

    void OcsProfileConnector.load_hovercard_action_icon (std.size_t hovercard_action_index, GLib.ByteArray icon_data) {
        if (hovercard_action_index >= this.current_hovercard._actions.size ()) {
            // Note: Probably could do more checking, like checking if the url is still the same.
            return;
        }
        const var icon = icon_data_to_pixmap (icon_data);
        if (icon.is_valid ()) {
            set_hovercard_action_icon (hovercard_action_index, icon.get ());
            return;
        }
        GLib.warn (lc_ocs_profile_connector) << "Could not load Svg icon from data" << icon_data;
    }

    void OcsProfileConnector.start_fetch_icon_job (std.size_t hovercard_action_index) {
        const var hovercard_action = this.current_hovercard._actions[hovercard_action_index];
        const var icon_job = new IconJob{this.account, hovercard_action._icon_url, this};
        connect (icon_job, &IconJob.job_finished,
            [this, hovercard_action_index] (GLib.ByteArray icon_data) {
                load_hovercard_action_icon (hovercard_action_index, icon_data);
            });
        connect (icon_job, &IconJob.error, this, [] (QNetworkReply.NetworkError error_type) {
            GLib.warn (lc_ocs_profile_connector) << "Could not fetch icon:" << error_type;
        });
    }

    void OcsProfileConnector.fetch_icons () {
        for (var hovercard_action_index = 0u; hovercard_action_index < this.current_hovercard._actions.size ();
             ++hovercard_action_index) {
            start_fetch_icon_job (hovercard_action_index);
        }
    }

    const Hovercard &OcsProfileConnector.hovercard () {
        return this.current_hovercard;
    }
    }
    