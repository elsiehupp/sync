/***********************************************************
@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace LibSync {

public class XattrVfsPluginFactory : DefaultPluginFactory<VfsXAttr> {

    construct {
        Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json");
        Q_INTERFACES (PluginFactory);
    }

}

} // namespace LibSync
} // namespace Occ
