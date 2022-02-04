/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

//  #pragma once


namespace Occ {

template<class PluginClass>
class DefaultPluginFactory : PluginFactory {

    /***********************************************************
    ***********************************************************/
    public override GLib.Object create (GLib.Object parent) {
        return new PluginClass (parent);
    }
}