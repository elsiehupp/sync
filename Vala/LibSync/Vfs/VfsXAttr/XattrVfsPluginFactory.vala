/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

public class XattrVfsPluginFactory : DefaultPluginFactory<VfsXAttr> {

    construct {
        Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json");
        Q_INTERFACES (Occ.PluginFactory);
    }

}

} // namespace LibSync
} // namespace Occ
