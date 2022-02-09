/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class Suffix_vfs_plugin_factory : GLib.Object, DefaultPluginFactory<Vfs_suffix> {
    Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
};