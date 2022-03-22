namespace Occ {
namespace LibSync {

/***********************************************************
@class XattrVfsPluginFactory

@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class XattrVfsPluginFactory : DefaultPluginFactory<VfsXAttr> {

    construct {
        Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json");
        Q_INTERFACES (PluginFactory);
    }

} // class XattrVfsPluginFactory

} // namespace LibSync
} // namespace Occ
