/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once


namespace Occ {

// Q_DECLARE_INTERFACE (Occ.PluginFactory, "org.owncloud.PluginFactory")

class PluginFactory {

    /***********************************************************
    ***********************************************************/
    public virtual ~PluginFactory () = default;
    public virtual GLib.Object* create (GLib.Object parent);
};

template<class PluginClass>
class DefaultPluginFactory : PluginFactory {

    /***********************************************************
    ***********************************************************/
    public override GLib.Object create (GLib.Object parent) {
        return new PluginClass (parent);
    }
};

/***********************************************************
Return the expected name of a plugin, for use with QPluginLoader
***********************************************************/
string plugin_file_name (string type, string name) {
    return "%1sync_%2_%3"
        .arg (APPLICATION_EXECUTABLE, type, name);
}





}
    