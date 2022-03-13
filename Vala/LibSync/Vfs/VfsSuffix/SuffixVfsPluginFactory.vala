/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

public class SuffixVfsPluginFactory : GLib.Object, DefaultPluginFactory<VfsSuffix> {
    Q_PLUGIN_METADATA (IID + "org.owncloud.PluginFactory" + FILE + "vfspluginmetadata.json")
    Q_INTERFACES (Occ.PluginFactory)
}

} // namespace LibSync
} // namespace Occ
