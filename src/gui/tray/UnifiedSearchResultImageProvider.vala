/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QtCore>
// #include <QQuickImageProvider>

namespace Occ {

/***********************************************************
@brief The UnifiedSearchResultImageProvider
@ingroup gui
Allows to fetch Unified Search result icon from the server or used a local resource
***********************************************************/

class UnifiedSearchResultImageProvider : QQuickAsyncImageProvider {
public:
    QQuickImageResponse *requestImageResponse (string &id, QSize &requestedSize) override;
};
}







/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QImage>
// #include <QPainter>
// #include <QSvgRenderer>

namespace {
    class AsyncImageResponse : QQuickImageResponse {
    public:
        AsyncImageResponse (string &id, QSize &requestedSize) {
            if (id.isEmpty ()) {
                setImageAndEmitFinished ();
                return;
            }
    
            _imagePaths = id.split (QLatin1Char (';'), Qt.SkipEmptyParts);
            _requestedImageSize = requestedSize;
    
            if (_imagePaths.isEmpty ()) {
                setImageAndEmitFinished ();
            } else {
                processNextImage ();
            }
        }
    
        void setImageAndEmitFinished (QImage &image = {}) {
            _image = image;
            emit finished ();
        }
    
        QQuickTextureFactory *textureFactory () const override {
            return QQuickTextureFactory.textureFactoryForImage (_image);
        }
    
    private:
        void processNextImage () {
            if (_index < 0 || _index >= _imagePaths.size ()) {
                setImageAndEmitFinished ();
                return;
            }
    
            if (_imagePaths.at (_index).startsWith (QStringLiteral (":/client"))) {
                setImageAndEmitFinished (QIcon (_imagePaths.at (_index)).pixmap (_requestedImageSize).toImage ());
                return;
            }
    
            const auto currentUser = Occ.UserModel.instance ().currentUser ();
            if (currentUser && currentUser.account ()) {
                const QUrl iconUrl (_imagePaths.at (_index));
                if (iconUrl.isValid () && !iconUrl.scheme ().isEmpty ()) {
                    // fetch the remote resource
                    const auto reply = currentUser.account ().sendRawRequest (QByteArrayLiteral ("GET"), iconUrl);
                    connect (reply, &QNetworkReply.finished, this, &AsyncImageResponse.slotProcessNetworkReply);
                    ++_index;
                    return;
                }
            }
    
            setImageAndEmitFinished ();
        }
    
    private slots:
        void slotProcessNetworkReply () {
            const auto reply = qobject_cast<QNetworkReply> (sender ());
            if (!reply) {
                setImageAndEmitFinished ();
                return;
            }
    
            const QByteArray imageData = reply.readAll ();
            // server returns "[]" for some some file previews (have no idea why), so, we use another image
            // from the list if available
            if (imageData.isEmpty () || imageData == QByteArrayLiteral ("[]")) {
                processNextImage ();
            } else {
                if (imageData.startsWith (QByteArrayLiteral ("<svg"))) {
                    // SVG image needs proper scaling, let's do it with QPainter and QSvgRenderer
                    QSvgRenderer svgRenderer;
                    if (svgRenderer.load (imageData)) {
                        QImage scaledSvg (_requestedImageSize, QImage.Format_ARGB32);
                        scaledSvg.fill ("transparent");
                        QPainter painterForSvg (&scaledSvg);
                        svgRenderer.render (&painterForSvg);
                        setImageAndEmitFinished (scaledSvg);
                        return;
                    } else {
                        processNextImage ();
                    }
                } else {
                    setImageAndEmitFinished (QImage.fromData (imageData));
                }
            }
        }
    
        QImage _image;
        QStringList _imagePaths;
        QSize _requestedImageSize;
        int _index = 0;
    };
    }
    
    namespace Occ {
    
    QQuickImageResponse *UnifiedSearchResultImageProvider.requestImageResponse (string &id, QSize &requestedSize) {
        return new AsyncImageResponse (id, requestedSize);
    }
    
    }
    