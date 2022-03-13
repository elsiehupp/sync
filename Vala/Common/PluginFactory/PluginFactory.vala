/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

namespace Occ {

// Q_DECLARE_INTERFACE (Occ.PluginFactory, "org.owncloud.PluginFactory")

public abstract class PluginFactory {

    /***********************************************************
    ***********************************************************/
    public abstract GLib.Object create (GLib.Object parent);

    /***********************************************************
    Return the expected name of a plugin, for use with QPluginLoader
    ***********************************************************/
    public static string plugin_filename (string type, string name) {
        return "%1sync_%2_%3"
            .arg (APPLICATION_EXECUTABLE, type, name);
    }

}

}
    