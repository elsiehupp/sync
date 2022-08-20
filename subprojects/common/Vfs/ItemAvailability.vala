namespace Occ {
namespace Common {

/***********************************************************
@enum enum ItemAvailability

A user-facing version of PinState.

PinStates communicate availability intent for an item, but
particular situations can get complex: An PinState.ALWAYS_LOCAL
folder can have ItemAvailability.ONLINE_ONLY files or
directories.

For users this is condensed to a few useful cases.

Note that this is only about intent*. The file could still
be out of date, or not have been synced for other reasons,
like errors.

Note: The numerical values and ordering of this enum are
relevant.

@author Christian Kamm <mail@ckamm.de>
@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public enum ItemAvailability {
    /***********************************************************
    The item and all its subitems are hydrated and pinned
    PinState.ALWAYS_LOCAL.

    This guarantees that all contents will be kept in sync.
    ***********************************************************/
    ALWAYS_LOCAL = 0,

    /***********************************************************
    The item and all its subitems are hydrated.

    This may change if the platform or client decide to
    dehydrate items that have PinState.UNSPECIFIED pin state.

    A folder with no file contents will have this availability.
    ***********************************************************/
    ALL_HYDRATED = 1,

    /***********************************************************
    There are dehydrated and hydrated items.

    This would happen if a dehydration happens to a
    PinState.UNSPECIFIED item that used to be hydrated.
    ***********************************************************/
    MIXED = 2,

    /***********************************************************
    There are only dehydrated items but the pin state isn't all
    ItemAvailability.ONLINE_ONLY.
    ***********************************************************/
    ALL_DEHYDRATED = 3,

    /***********************************************************
    The item and all its subitems are dehydrated and
    ItemAvailability.ONLINE_ONLY.

    This guarantees that contents will not take up space.
    ***********************************************************/
    ONLINE_ONLY = 4;

    /***********************************************************
    Returns a translated string indicating the current
    availability.

    This will be used in context menus to describe the current
    state.
    ***********************************************************/
    //  public static string to_string (ItemAvailability availability) {
    //      switch (availability) {
    //      case ItemAvailability.ALWAYS_LOCAL:
    //          return _("Always available locally");
    //      case ItemAvailability.ALL_HYDRATED:
    //          return _("Currently available locally");
    //      case ItemAvailability.MIXED:
    //          return _("Some available online only");
    //      case ItemAvailability.ALL_DEHYDRATED:
    //      case ItemAvailability.ONLINE_ONLY:
    //          return _("Available online only");
    //      }
    //      GLib.assert_not_reached ();
    //  }


    //  /***********************************************************
    //  Translated text for "free up local space" (and unpinning the
    //  item)
    //  ***********************************************************/
    //  public static string vfs_free_space_action_text () {
    //      return _("Free up local space");
    //  }

} // enum ItemAvailability

} // namespace AbstractVfs
} // namespace Occ
