/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Image>
//  #include <QPainter>
//  #include <QSvgRenderer>
//  #include <QtCore>
//  #include <QQuickImageProvider>

namespace Occ {
namespace Ui {

class AsyncImageResponse : QQuickImageResponse {

    public AsyncImageResponse (string identifier, QSize requested_size) {
        if (identifier.is_empty ()) {
            image_and_emit_finished ();
            return;
        }

        this.image_paths = identifier.split (';', Qt.SkipEmptyParts);
        this.requested_image_size = requested_size;

        if (this.image_paths.is_empty ()) {
            image_and_emit_finished ();
        } else {
            process_next_image ();
        }
    }

    public void image_and_emit_finished (Gtk.Image image = {}) {
        this.image = image;
        /* emit */ finished ();
    }

    public QQuick_texture_factory texture_factory () override {
        return QQuick_texture_factory.texture_factory_for_image (this.image);
    }


    private void process_next_image () {
        if (this.index < 0 || this.index >= this.image_paths.size ()) {
            image_and_emit_finished ();
            return;
        }

        if (this.image_paths.at (this.index).starts_with (QStringLiteral (":/client"))) {
            image_and_emit_finished (QIcon (this.image_paths.at (this.index)).pixmap (this.requested_image_size).to_image ());
            return;
        }

        const var current_user = Occ.UserModel.instance ().is_current_user ();
        if (current_user && current_user.account ()) {
            const GLib.Uri icon_url (this.image_paths.at (this.index));
            if (icon_url.is_valid () && !icon_url.scheme ().is_empty ()) {
                // fetch the remote resource
                const var reply = current_user.account ().send_raw_request (QByteArrayLiteral ("GET"), icon_url);
                connect (reply, &Soup.Reply.on_signal_finished, this, &AsyncImageResponse.on_signal_process_network_reply);
                ++this.index;
                return;
            }
        }

        image_and_emit_finished ();
    }


/***********************************************************
***********************************************************/
private slots:
    void on_signal_process_network_reply () {
        const var reply = qobject_cast<Soup.Reply> (sender ());
        if (!reply) {
            image_and_emit_finished ();
            return;
        }

        const GLib.ByteArray image_data = reply.read_all ();
        // server returns "[]" for some some file previews (have no idea why), so, we use another image
        // from the list if available
        if (image_data.is_empty () || image_data == QByteArrayLiteral ("[]")) {
            process_next_image ();
        } else {
            if (image_data.starts_with (QByteArrayLiteral ("<svg"))) {
                // SVG image needs proper scaling, let's do it with QPainter and QSvgRenderer
                QSvgRenderer svg_renderer;
                if (svg_renderer.on_signal_load (image_data)) {
                    Gtk.Image scaled_svg (this.requested_image_size, Gtk.Image.Format_ARGB32);
                    scaled_svg.fill ("transparent");
                    QPainter painter_for_svg (&scaled_svg);
                    svg_renderer.render (&painter_for_svg);
                    image_and_emit_finished (scaled_svg);
                    return;
                } else {
                    process_next_image ();
                }
            } else {
                image_and_emit_finished (Gtk.Image.from_data (image_data));
            }
        }
    }

    Gtk.Image this.image;
    string[] this.image_paths;
    QSize this.requested_image_size;
    int this.index = 0;
}
    