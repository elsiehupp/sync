/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

// #pragma once

// #include <QQuickImageProvider>

namespace Occ {
namespace Ui {

    class SvgImageProvider : QQuickImageProvider {
    public:
        SvgImageProvider ();
        QImage requestImage (string &id, QSize *size, QSize &requestedSize) override;
    };


    SvgImageProvider.SvgImageProvider ()
        : QQuickImageProvider (QQuickImageProvider.Image) {
    }

    QImage SvgImageProvider.requestImage (string &id, QSize *size, QSize &requestedSize) {
        Q_ASSERT (!id.isEmpty ());

        const auto idSplit = id.split (QStringLiteral ("/"), Qt.SkipEmptyParts);

        if (idSplit.isEmpty ()) {
            qCWarning (lcSvgImageProvider) << "Image id is incorrect!";
            return {};
        }

        const auto pixmapName = idSplit.at (0);
        const auto pixmapColor = idSplit.size () > 1 ? QColor (idSplit.at (1)) : QColorConstants.Svg.black;

        if (pixmapName.isEmpty () || !pixmapColor.isValid ()) {
            qCWarning (lcSvgImageProvider) << "Image id is incorrect!";
            return {};
        }

        return IconUtils.createSvgImageWithCustomColor (pixmapName, pixmapColor, size, requestedSize);
    }
}
}
