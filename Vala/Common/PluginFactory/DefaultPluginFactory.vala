namespace Occ {

/***********************************************************
@class DefaultPluginFactory

@author Dominik Schmidt <dschmidt@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/
public class DefaultPluginFactory : PluginFactory {

    //  template<class PluginClass>

    /***********************************************************
    ***********************************************************/
    public override GLib.Object create (GLib.Object parent) {
        return new PluginClass (parent);
    }
}

} // namespace Occ
