/*
 * Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <theme.h>

// #include <QFile>
// #include <QLoggingCategory>
// #include <QPainter>
// #include <QPixmapCache>
// #include <QSvgRenderer>

namespace {
QString findSvgFilePath (QString &fileName, QStringList &possibleColors) {
    QString result;
    result = QString{OCC::Theme::themePrefix} + fileName;
    if (QFile::exists (result)) {
        return result;
    } else {
        for (auto &color : possibleColors) {
            result = QString{OCC::Theme::themePrefix} + color + QStringLiteral ("/") + fileName;

            if (QFile::exists (result)) {
                return result;
            }
        }
        result.clear ();
    }

    return result;
}
}

namespace OCC {
namespace Ui {
namespace IconUtils {
Q_LOGGING_CATEGORY (lcIconUtils, "nextcloud.gui.iconutils", QtInfoMsg)
QPixmap pixmapForBackground (QString &fileName, QColor &backgroundColor) {
    Q_ASSERT (!fileName.isEmpty ());

    const auto pixmapColor = backgroundColor.isValid () && !Theme::isDarkColor (backgroundColor)
        ? QColorConstants::Svg::black
        : QColorConstants::Svg::white;
    ;
    return createSvgPixmapWithCustomColorCached (fileName, pixmapColor);
}

QImage createSvgImageWithCustomColor (QString &fileName, QColor &customColor, QSize *originalSize, QSize &requestedSize) {
    Q_ASSERT (!fileName.isEmpty ());
    Q_ASSERT (customColor.isValid ());

    QImage result{};

    if (fileName.isEmpty () || !customColor.isValid ()) {
        qWarning (lcIconUtils) << "invalid fileName or customColor";
        return result;
    }

    // some icons are present in white or black only, so, we need to check both when needed
    const auto iconBaseColors = QStringList{QStringLiteral ("black"), QStringLiteral ("white")};

    // check if there is an existing image matching the custom color {
        const auto customColorName = [&customColor] () {
            auto result = customColor.name ();
            if (result.startsWith (QStringLiteral ("#"))) {
                if (result == QStringLiteral ("#000000")) {
                    result = QStringLiteral ("black");
                }
                if (result == QStringLiteral ("#ffffff")) {
                    result = QStringLiteral ("white");
                }
            }
            return result;
        } ();

        if (iconBaseColors.contains (customColorName)) {
            result = QImage{QString{OCC::Theme::themePrefix} + customColorName + QStringLiteral ("/") + fileName};
            if (!result.isNull ()) {
                return result;
            }
        }
    }

    // find the first matching svg file
    const auto sourceSvg = findSvgFilePath (fileName, iconBaseColors);

    Q_ASSERT (!sourceSvg.isEmpty ());
    if (sourceSvg.isEmpty ()) {
        qWarning (lcIconUtils) << "Failed to find base SVG file for" << fileName;
        return result;
    }

    result = drawSvgWithCustomFillColor (sourceSvg, customColor, originalSize, requestedSize);

    Q_ASSERT (!result.isNull ());
    if (result.isNull ()) {
        qWarning (lcIconUtils) << "Failed to load pixmap for" << fileName;
    }

    return result;
}

QPixmap createSvgPixmapWithCustomColorCached (QString &fileName, QColor &customColor, QSize *originalSize, QSize &requestedSize) {
    QPixmap cachedPixmap;

    const auto customColorName = customColor.name ();

    const QString cacheKey = fileName + QStringLiteral (",") + customColorName;

    // check for existing QPixmap in cache
    if (QPixmapCache::find (cacheKey, &cachedPixmap)) {
        if (originalSize) {
            *originalSize = {};
        }
        return cachedPixmap;
    }

    cachedPixmap = QPixmap::fromImage (createSvgImageWithCustomColor (fileName, customColor, originalSize, requestedSize));

    if (!cachedPixmap.isNull ()) {
        QPixmapCache::insert (cacheKey, cachedPixmap);
    }

    return cachedPixmap;
}

QImage drawSvgWithCustomFillColor (
    const QString &sourceSvgPath, QColor &fillColor, QSize *originalSize, QSize &requestedSize) {
    QSvgRenderer svgRenderer;

    if (!svgRenderer.load (sourceSvgPath)) {
        qCWarning (lcIconUtils) << "Could no load initial SVG image";
        return {};
    }

    const auto reqSize = requestedSize.isValid () ? requestedSize : svgRenderer.defaultSize ();

    if (originalSize) {
        *originalSize = svgRenderer.defaultSize ();
    }

    // render source image
    QImage svgImage (reqSize, QImage::Format_ARGB32); {
        QPainter svgImagePainter (&svgImage);
        svgImage.fill (Qt::GlobalColor::transparent);
        svgRenderer.render (&svgImagePainter);
    }

    // draw target image with custom fillColor
    QImage image (reqSize, QImage::Format_ARGB32);
    image.fill (QColor (fillColor)); {
        QPainter imagePainter (&image);
        imagePainter.setCompositionMode (QPainter::CompositionMode_DestinationIn);
        imagePainter.drawImage (0, 0, svgImage);
    }

    return image;
}
}
}
}
