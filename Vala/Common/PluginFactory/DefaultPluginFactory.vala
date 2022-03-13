/***********************************************************
Copyright (C) by Dominik Schmidt <dschmidt@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/



namespace Occ {

//  template<class PluginClass>
public class DefaultPluginFactory : PluginFactory {

    /***********************************************************
    ***********************************************************/
    public override GLib.Object create (GLib.Object parent) {
        return new PluginClass (parent);
    }
}