/*
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

This library is free software; you can redistribute it and
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later versi

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GN
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

// #pragma once

// #include <GLib.Object>

namespace Occ {

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
QString pluginFileName (QString &type, QString &name);

}

Q_DECLARE_INTERFACE (Occ.PluginFactory, "org.owncloud.PluginFactory")
