/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The FakeProvider
is a simple structure that represents initial list of providers and their properties
***********************************************************/
class FakeProvider {

    /***********************************************************
    ***********************************************************/
    public string this.identifier;
    public string this.name;
    public int32 this.order = std.numeric_limits<int32>.max ();


    /***********************************************************
    ***********************************************************/
    public uint32 this.numItemsToInsert = 5; // how many fake resuls to insert
}

// this will be used when initializing fake search results data for each provider
static const GLib.Vector<FakeProvider> fakeProvidersInitInfo = { {QStringLiteral ("settings_apps"), QStringLiteral ("Apps"), -50, 10}, {QStringLiteral ("talk-message"), QStringLiteral ("Messages"), -2, 17}, {QStringLiteral ("files"), QStringLiteral ("Files"), 5, 3}, {QStringLiteral ("deck"), QStringLiteral ("Deck"), 10, 5}, {QStringLiteral ("comments"), QStringLiteral ("Comments"), 10, 2}, {QStringLiteral ("mail"), QStringLiteral ("Mails"), 10, 15}, {QStringLiteral ("calendar"), QStringLiteral ("Events"), 30, 11}
}

static GLib.ByteArray fake404Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":404,"message":"Invalid query, please check the syntax. API specifications are here : http:\/\/www.freedesktop.org\/wiki\/Specifications\/open-collaboration-services.\n"},"data":[]}}
)";

static GLib.ByteArray fake400Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":400,"message":"Parameter is incorrect.\n"},"data":[]}}
)";

static GLib.ByteArray fake500Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":500,"message":"Internal Server Error.\n"},"data":[]}}
)";
