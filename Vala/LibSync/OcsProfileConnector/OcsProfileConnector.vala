//  #pragma once

//  #include <QPixmap>
//  #include <QJsonObject>
//  #include <QJsonDocument>
//  #include <QJsonArray>
//  #include <QLoggingCategory>
//  #include <QIcon>
//  #include <QPainter>
//  #include <Gtk.Image>
//  #include <QSvgRenderer>
//  #include <QPixmap>
//  #include <QPixmapCache>

namespace Occ {
namespace LibSync {

public class OcsProfileConnector : GLib.Object {

    private unowned Account account;
    private Hovercard current_hovercard;

    signal void error ();
    signal void hovercard_fetched ();
    signal void icon_loaded (size_t hovercard_action_index);

    /***********************************************************
    ***********************************************************/
    public OcsProfileConnector.for_account (Account account, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_hovercard (string user_id) {
        if (this.account.server_version_int () < Account.make_server_version (23, 0, 0)) {
            GLib.info ("Server version " + this.account.server_version ()
                + " does not support profile page.");
            /* emit */ error ();
            return;
        }
        const string url = "/ocs/v2.php/hovercard/v1/%1".arg (user_id);
        var job = new JsonApiJob (this.account, url, this);
        JsonApiJob.signal_json_received.connect (job, this, OcsProfileConnector.on_signal_hovercard_fetched);
        job.start ();
    }


    /***********************************************************
    ***********************************************************/
    public Hovercard hovercard () {
        return this.current_hovercard;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_hovercard_fetched (QJsonDocument json, int status_code) {
        GLib.debug ("Hovercard fetched: " + json);

        if (status_code != 200) {
            GLib.info ("Fetching of hovercard finished with status code " + status_code);
            return;
        }
        var json_data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("actions");
        GLib.assert (json_data.is_array ());
        this.current_hovercard = json_to_hovercard (json_data.to_array ());
        fetch_icons ();
        /* emit */ hovercard_fetched ();
    }


    /***********************************************************
    ***********************************************************/
    private void fetch_icons () {
        for (var hovercard_action_index = 0u; hovercard_action_index < this.current_hovercard.actions.size ();
             ++hovercard_action_index) {
            start_fetch_icon_job (hovercard_action_index);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void start_fetch_icon_job (size_t hovercard_action_index) {
        var hovercard_action = this.current_hovercard.actions[hovercard_action_index];
        var icon_job = new IconJob (this.account, hovercard_action.icon_url, this);
        connect (
            icon_job,
            IconJob.signal_job_finished,
            this.on_signal_icon_job_finished
        );
        connect (
            icon_job,
            IconJob.error,
            this,
            this.on_signal_icon_job_error
        );
    }


    private void on_signal_icon_job_finished (size_t hovercard_action_index, string icon_data) {
        load_hovercard_action_icon (hovercard_action_index, icon_data);
    }


    private void on_signal_icon_job_error (Soup.Reply.NetworkError error_type) {
        GLib.warning ("Could not fetch icon: " + error_type);
    }


    /***********************************************************
    ***********************************************************/
    private void hovercard_action_icon (size_t index, QPixmap pixmap) {
        var hovercard_action = this.current_hovercard.actions[index];
        QPixmapCache.insert (hovercard_action.icon_url.to_string (), pixmap);
        hovercard_action.icon = pixmap;
        /* emit */ icon_loaded (index);
    }


    /***********************************************************
    ***********************************************************/
    private void load_hovercard_action_icon (size_t hovercard_action_index, string icon_data) {
        if (hovercard_action_index >= this.current_hovercard.actions.size ()) {
            // Note: Probably could do more checking, like checking if the url is still the same.
            return;
        }
        var icon = icon_data_to_pixmap (icon_data);
        if (icon.is_valid ()) {
            hovercard_action_icon (hovercard_action_index, icon);
            return;
        }
        GLib.warning ("Could not load Svg icon from data " + icon_data);
    }


    private static Occ.HovercardAction json_to_action (QJsonObject json_action_object) {
        var icon_url = json_action_object.value ("icon").to_string ("no-icon");
        QPixmap icon_pixmap;
        Occ.HovercardAction hovercard_action = new Occ.HovercardAction (
            json_action_object.value ("title").to_string ("No title"), icon_url,
            json_action_object.value ("hyperlink").to_string ("no-link")
        );
        if (QPixmapCache.find (icon_url, icon_pixmap)) {
            hovercard_action.icon = icon_pixmap;
        }
        return hovercard_action;
    }


    private static Occ.Hovercard json_to_hovercard (QJsonArray json_data_array) {
        Occ.Hovercard hovercard;
        hovercard.actions.reserve (json_data_array.size ());
        foreach (var json_entry in json_data_array) {
            GLib.assert (json_entry.is_object ());
            if (!json_entry.is_object ()) {
                continue;
            }
            hovercard.actions.push_back (json_to_action (json_entry.to_object ()));
        }
        return hovercard;
    }


    private static Occ.Optional<QPixmap> create_pixmap_from_svg_data (string icon_data) {
        QSvgRenderer svg_renderer;
        if (!svg_renderer.on_signal_load (icon_data)) {
            return {};
        }
        QSize image_size = new QSize (16, 16);
        if (Occ.Theme.is_hidpi ()) {
            image_size = new QSize (32, 32);
        }
        Gtk.Image scaled_svg = new Gtk.Image (image_size, Gtk.Image.FormatARGB32);
        scaled_svg.fill ("transparent");
        QPainter svg_painter = new QPainter (scaled_svg);
        svg_renderer.render (&svg_painter);
        return QPixmap.from_image (scaled_svg);
    }


    private static Occ.Optional<QPixmap> icon_data_to_pixmap (string icon_data) {
        if (!icon_data.starts_with ("<svg")) {
            return {};
        }
        return create_pixmap_from_svg_data (icon_data);
    }

} // class OcsProfileConnector

} // namespace LibSync
} // namespace Occ
    