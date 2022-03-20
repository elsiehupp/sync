/***********************************************************
@author Christian Kamm <mail@ckamm.de>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

public class SuffixVfsPluginFactory : GLib.Object, DefaultPluginFactory<VfsSuffix> {

    construct {
        Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json");
        Q_INTERFACES (PluginFactory);
    }

}

} // namespace LibSync
} // namespace Occ
