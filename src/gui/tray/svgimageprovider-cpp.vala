/*
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QLoggingCategory>

namespace Occ {
namespace Ui {
    Q_LOGGING_CATEGORY (lcSvgImageProvider, "nextcloud.gui.svgimageprovider", QtInfoMsg)

    SvgImageProvider.SvgImageProvider ()
        : QQuickImageProvider (QQuickImageProvider.Image) {
    }

    QImage SvgImageProvider.requestImage (QString &id, QSize *size, QSize &requestedSize) {
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
