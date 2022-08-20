namespace Occ {
namespace Common {

/***********************************************************
@public enum PinState

@details Determines whether items should be available
locally permanently or not

The idea is that files and folders can be marked with the
user intent
on availability.

The PinState.INHERITED state is u
parent path would do.

The pin state of a directory usually only matters for the
initial pin a hydration state of new remote files. It's
perfectly possible for a PinState.ALWAYS_LOCAL directory to
have only ItemAvailability.ONLINE_ONLY items states is
usually done recursively, so one'd need to set the folder to
pinned and then each contained item to unpinned)

Note: This enum intentionally mimics CF_PIN_STATE of Windows
cfapi.

@author Christian Kamm <mail@ckamm.de>
@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public enum PinState {
    /***********************************************************
    The pin state is derived from the state of the parent folder.

    For example new remote files on_signal_start out in this state, following
    the state of their parent folder.

    This state is used purely for resetting pin states to their derived
    value. The effective state for an item will never be "PinState.INHERITED".
    ***********************************************************/
    INHERITED = 0,

    /***********************************************************
    The file shall be available and up to date locally.

    Also known as "pinned". Pinned dehydrated files shall be hydrated
    as soon as possible.
    ***********************************************************/
    ALWAYS_LOCAL = 1,

    /***********************************************************
    File shall be a dehydrated placeholder, filled on demand.

    Also known as "unpinned". Unpinned hydrated files shall be dehydrated
    as soon as possible.

    If a unpinned file becomes hydrated (such as due to an implicit hydration
    where the user requested access to the file's data) its pin state changes
    to PinState.UNSPECIFIED.
    ***********************************************************/
    ONLINE_ONLY = 2,

    /***********************************************************
    The user hasn't made a decision. The client or platform may hydrate or
    dehydrate as they see fit.

    New remote files in unspecified directories on_signal_start unspecified, and
    dehydrated (which is an arbitrary decision).
    ***********************************************************/
    UNSPECIFIED = 3,

    /***********************************************************
    This is an error state that should be replaced with an error
    domain.
    ***********************************************************/
    UNKOWN = 4;

    /***********************************************************
    Translated text for "making items always available locally"
    ***********************************************************/
    //  public static string vfs_pin_action_text () {
    //      return _("Make always available locally");
    //  }

} // enum PinState

} // namespace AbstractVfs
} // namespace Occ
