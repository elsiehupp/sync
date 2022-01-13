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

// #include <QColor>
// #include <QPixmap>

namespace OCC {
namespace Ui {
namespace IconUtils {
QPixmap pixmapForBackground (QString &fileName, QColor &backgroundColor);
QImage createSvgImageWithCustomColor (QString &fileName, QColor &customColor, QSize *originalSize = nullptr, QSize &requestedSize = {});
QPixmap createSvgPixmapWithCustomColorCached (QString &fileName, QColor &customColor, QSize *originalSize = nullptr, QSize &requestedSize = {});
QImage drawSvgWithCustomFillColor (QString &sourceSvgPath, QColor &fillColor, QSize *originalSize = nullptr, QSize &requestedSize = {});
}
}
}
#endif // ICONUTILS_H
