namespace Occ {
namespace Testing {

/***********************************************************
@class AbstractTestTheme

@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public abstract class AbstractTestTheme : GLib.Object {

    /***********************************************************
    ***********************************************************/
    protected AbstractTestTheme () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }

} // class AbstractTestTheme

} // namespace Testing
} // namespace Occ
