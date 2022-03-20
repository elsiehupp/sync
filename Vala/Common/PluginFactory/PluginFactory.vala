namespace Occ {

/***********************************************************
@class PluginFactory

@author Dominik Schmidt <dschmidt@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public abstract class PluginFactory {

    /***********************************************************
    ***********************************************************/
    public abstract GLib.Object create (GLib.Object parent);

    /***********************************************************
    Return the expected name of a plugin, for use with QPluginLoader
    ***********************************************************/
    public static string plugin_filename (string type, string name) {
        return "%1sync_%2_%3"
            .printf (APPLICATION_EXECUTABLE, type, name);
    }

}

}
    