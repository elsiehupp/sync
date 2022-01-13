/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <limits>

// #include <QtCore>

namespace Occ {

/***********************************************************
@brief The UnifiedSearchResult class
@ingroup gui
Simple data structure that represents single Unified Search result
***********************************************************/

struct UnifiedSearchResult {
    enum Type : uint8 {
        Default,
        FetchMoreTrigger,
    };

    static string typeAsString (UnifiedSearchResult.Type type);

    string _title;
    string _subline;
    string _providerId;
    string _providerName;
    bool _isRounded = false;
    int32 _order = std.numeric_limits<int32>.max ();
    QUrl _resourceUrl;
    string _icons;
    Type _type = Type.Default;
};
}









/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>

namespace Occ {

    string UnifiedSearchResult.typeAsString (UnifiedSearchResult.Type type) {
        string result;
    
        switch (type) {
        case Default:
            result = QStringLiteral ("Default");
            break;
    
        case FetchMoreTrigger:
            result = QStringLiteral ("FetchMoreTrigger");
            break;
        }
        return result;
    }
    }
    