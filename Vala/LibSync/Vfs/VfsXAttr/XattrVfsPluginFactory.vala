/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class XattrVfsPluginFactory : GLib.Object, DefaultPluginFactory<VfsXAttr> {
    Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};