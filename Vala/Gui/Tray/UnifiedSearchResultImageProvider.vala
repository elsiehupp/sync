/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QImage>
//  #include <QPainter>
//  #include <QSvgRenderer>

//  #pragma once

//  #include <QtCore>
//  #include <QQuick_image_provider>

namespace Occ {

/***********************************************************
@brief The Unified_search_result_image_provider
@ingroup gui
Allows to fetch Unified Search result icon from the server or used a local resource
***********************************************************/

class Unified_search_result_image_provider : QQuick_async_image_provider {

    /***********************************************************
    ***********************************************************/
    public QQuick_image_response request_image_response (string identifier, QSize requested_size) override;
}
}








namespace {
    class Async_image_response : QQuick_image_response {

        public Async_image_response (string identifier, QSize requested_size) {
            if (identifier.is_empty ()) {
                set_image_and_emit_finished ();
                return;
            }

            this.image_paths = identifier.split (';', Qt.Skip_empty_parts);
            this.requested_image_size = requested_size;

            if (this.image_paths.is_empty ()) {
                set_image_and_emit_finished ();
            } else {
                process_next_image ();
            }
        }

        public void set_image_and_emit_finished (QImage image = {}) {
            this.image = image;
            /* emit */ finished ();
        }

        public QQuick_texture_factory texture_factory () override {
            return QQuick_texture_factory.texture_factory_for_image (this.image);
        }


        private void process_next_image () {
            if (this.index < 0 || this.index >= this.image_paths.size ()) {
                set_image_and_emit_finished ();
                return;
            }

            if (this.image_paths.at (this.index).starts_with (QStringLiteral (":/client"))) {
                set_image_and_emit_finished (QIcon (this.image_paths.at (this.index)).pixmap (this.requested_image_size).to_image ());
                return;
            }

            const var current_user = Occ.User_model.instance ().current_user ();
            if (current_user && current_user.account ()) {
                const GLib.Uri icon_url (this.image_paths.at (this.index));
                if (icon_url.is_valid () && !icon_url.scheme ().is_empty ()) {
                    // fetch the remote resource
                    const var reply = current_user.account ().send_raw_request (QByteArrayLiteral ("GET"), icon_url);
                    connect (reply, &Soup.Reply.on_finished, this, &Async_image_response.on_process_network_reply);
                    ++this.index;
                    return;
                }
            }

            set_image_and_emit_finished ();
        }


    /***********************************************************
    ***********************************************************/
    private slots:
        void on_process_network_reply () {
            const var reply = qobject_cast<Soup.Reply> (sender ());
            if (!reply) {
                set_image_and_emit_finished ();
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
                    if (svg_renderer.on_load (image_data)) {
                        QImage scaled_svg (this.requested_image_size, QImage.Format_ARGB32);
                        scaled_svg.fill ("transparent");
                        QPainter painter_for_svg (&scaled_svg);
                        svg_renderer.render (&painter_for_svg);
                        set_image_and_emit_finished (scaled_svg);
                        return;
                    } else {
                        process_next_image ();
                    }
                } else {
                    set_image_and_emit_finished (QImage.from_data (image_data));
                }
            }
        }

        QImage this.image;
        string[] this.image_paths;
        QSize this.requested_image_size;
        int this.index = 0;
    };


    QQuick_image_response *Unified_search_result_image_provider.request_image_response (string identifier, QSize requested_size) {
        return new Async_image_response (identifier, requested_size);
    }

}
    