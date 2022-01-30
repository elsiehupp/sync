/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>

// #pragma once

// #include <limits>

// #include <QtCore>

namespace Occ {

/***********************************************************
@brief The Unified_search_result class
@ingroup gui
Simple data structure that represents single Unified Search result
***********************************************************/

struct Unified_search_result {
    enum Type : uint8 {
        Default,
        Fetch_more_trigger,
    };

    /***********************************************************
    ***********************************************************/
    static string type_as_string (Unified_search_result.Type type);

    string _title;
    string _subline;
    string _provider_id;
    string _provider_name;
    bool _is_rounded = false;
    int32 _order = std.numeric_limits<int32>.max ();
    GLib.Uri _resource_url;
    string _icons;
    Type _type = Type.Default;
};


    string Unified_search_result.type_as_string (Unified_search_result.Type type) {
        string result;

        switch (type) {
        case Default:
            result = QStringLiteral ("Default");
            break;

        case Fetch_more_trigger:
            result = QStringLiteral ("Fetch_more_trigger");
            break;
        }
        return result;
    }
    }
    