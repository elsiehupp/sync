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

// #pragma once

// #include <QQuickImageProvider>

namespace Occ {
namespace Ui {
    class SvgImageProvider : QQuickImageProvider {
    public:
        SvgImageProvider ();
        QImage requestImage (QString &id, QSize *size, QSize &requestedSize) override;
    };
}
}
