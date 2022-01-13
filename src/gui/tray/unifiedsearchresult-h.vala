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

// #include <limits>

// #include <QtCore>

namespace Occ {

/**
@brief The UnifiedSearchResult class
@ingroup gui
Simple data structure that represents single Unified Search result
*/

struct UnifiedSearchResult {
    enum Type : uint8 {
        Default,
        FetchMoreTrigger,
    };

    static QString typeAsString (UnifiedSearchResult.Type type);

    QString _title;
    QString _subline;
    QString _providerId;
    QString _providerName;
    bool _isRounded = false;
    int32 _order = std.numeric_limits<int32>.max ();
    QUrl _resourceUrl;
    QString _icons;
    Type _type = Type.Default;
};
}
