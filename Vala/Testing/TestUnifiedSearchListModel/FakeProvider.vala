/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Testing {

/***********************************************************
@brief The FakeProvider
is a simple structure that represents initial list of providers and their properties
***********************************************************/
public class FakeProvider {

    /***********************************************************
    ***********************************************************/
    public string this.identifier;
    public string this.name;
    public int32 this.order = std.numeric_limits<int32>.max ();


    /***********************************************************
    ***********************************************************/
    public uint32 this.number_of_items_to_insert = 5; // how many fake resuls to insert
}

// this will be used when initializing fake search results data for each provider
const GLib.Vector<FakeProvider> fake_providers_init_info = {
    {
        "settings_apps", "Apps", -50, 10
    },
    {
        "talk-message", "Messages", -2, 17
    },
    {
        "files", "Files", 5, 3
    },
    {
        "deck", "Deck", 10, 5
    },
    {
        "comments", "Comments", 10, 2
    },
    {
        "mail", "Mails", 10, 15
    },
    {
        "calendar", "Events", 30, 11
    }
};

static GLib.ByteArray fake_404_response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":404,"message":"Invalid query, please check the syntax. API specifications are here : http:\/\/www.freedesktop.org\/wiki\/Specifications\/open-collaboration-services.\n"},"data":[]}}
)";

static GLib.ByteArray fake400Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":400,"message":"Parameter is incorrect.\n"},"data":[]}}
)";

static GLib.ByteArray fake500Response = R" ( {"ocs":{"meta":{"status":"failure","statuscode":500,"message":"Internal Server Error.\n"},"data":[]}}
)";
