namespace Occ {
namespace LibSync {

/***********************************************************
@class SuffixVfsPluginFactory

@author Christian Kamm <mail@ckamm.de>

@copyright GPLv3 or Later
***********************************************************/
public class SuffixVfsPluginFactory : GLib.Object, DefaultPluginFactory<VfsSuffix> {

    construct {
        Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json");
        Q_INTERFACES (PluginFactory);
    }

}

} // namespace LibSync
} // namespace Occ
