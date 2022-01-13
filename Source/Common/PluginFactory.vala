/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>

namespace Occ {

Q_DECLARE_INTERFACE (Occ.PluginFactory, "org.owncloud.PluginFactory")

class PluginFactory {
public:
    virtual ~PluginFactory ();
    virtual GLib.Object* create (GLib.Object* parent) = 0;
};

template<class PluginClass>
class DefaultPluginFactory : PluginFactory {
public:
    GLib.Object* create (GLib.Object *parent) override {
        return new PluginClass (parent);
    }
};

/// Return the expected name of a plugin, for use with QPluginLoader
string pluginFileName (string &type, string &name);



PluginFactory.~PluginFactory () = default;

string pluginFileName (string &type, string &name) {
    return QStringLiteral ("%1sync_%2_%3")
        .arg (QStringLiteral (APPLICATION_EXECUTABLE), type, name);
}
    
}
    