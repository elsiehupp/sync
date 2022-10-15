namespace Occ {
namespace LibSync {

/***********************************************************
@class XattrVfsPluginFactory

@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class XattrVfsPluginFactory : Common.DefaultPluginFactory<VfsXAttr> {

    construct {
        //  Q_PLUGIN_METADATA (IID + "org.owncloud.AbstractPluginFactory" + FILE + "vfspluginmetadata.json");
        //  Q_INTERFACES (AbstractPluginFactory);
    }

} // class XattrVfsPluginFactory

} // namespace LibSync
} // namespace Occ
