namespace Occ {
namespace Common {

/***********************************************************
@class AbstractPluginFactory

@author Dominik Schmidt <dschmidt@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public abstract class AbstractPluginFactory : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public abstract GLib.Object create (GLib.Object parent);

    /***********************************************************
    Return the expected name of a plugin, for use with GLib.PluginLoader
    ***********************************************************/
    public static string plugin_filename (string type, string name) {
        return "%1sync_%2_%3"
            .printf (Common.Config.APPLICATION_EXECUTABLE, type, name);
    }

} // class AbstractPluginFactory

} // namespace Common
} // namespace Occ
