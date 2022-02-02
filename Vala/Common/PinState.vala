/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>
Copyright (C) by Hannah von Reth <hannah.vonreth@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

namespace PinStateEnums {

/***********************************************************
Determines whether items should be available locally permanently or not

The idea is that files and folders can be marked with the user intent
on availability.

The PinState.INHERITED state is u
parent path would do.

The pin state of a directory usually only matters for the initial pin an
hydration state of new remote files. It's perfectly possible for a
PinState.ALWAYS_LOCAL directory to have only VfsItemAvailability.ONLINE_ONLY items
states is usually done recursively, so one'd need to set the folder to
pinned and then each contained item to unpinned)

Note: This enum intentionally mimics CF_PIN_STATE of Windows cfapi.
***********************************************************/
enum PinState {
    /***********************************************************
    The pin state is derived from the state of the parent folder.

    For example new remote files on_start out in this state, following
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
    VfsItemAvailability.ONLINE_ONLY = 2,

    /***********************************************************
    The user hasn't made a decision. The client or platform may hydrate or
    dehydrate as they see fit.

    New remote files in unspecified directories on_start unspecified, and
    dehydrated (which is an arbitrary decision).
    ***********************************************************/
    UNSPECIFIED = 3,
}

/***********************************************************
A user-facing version of PinState.

PinStates communicate availability intent for an item, but particular
situations can get complex: An PinState.ALWAYS_LOCAL folder can have VfsItemAvailability.ONLINE_ONLY
files or directories.

For users this is condensed to a few useful cases.

Note that this is only about intent*. The file could still be out of date,
or not have been synced for other reasons, like errors.

Note: The numerical values and ordering of this enum are relevant.
***********************************************************/
enum VfsItemAvailability {
    /***********************************************************
    The item and all its subitems are hydrated and pinned PinState.ALWAYS_LOCAL.

    This guarantees that all contents will be kept in sync.
    ***********************************************************/
    ALWAYS_LOCAL = 0,

    /***********************************************************
    The item and all its subitems are hydrated.

    This may change if the platform or client decide to dehydrate items
    that have PinState.UNSPECIFIED pin state.

    A folder with no file contents will have this availability.
    ***********************************************************/
    ALL_HYDRATED = 1,

    /***********************************************************
    There are dehydrated and hydrated items.

    This would happen if a dehydration happens to a PinState.UNSPECIFIED item that
    used to be hydrated.
    ***********************************************************/
    MIXED = 2,

    /***********************************************************
    There are only dehydrated items but the pin state isn't all VfsItemAvailability.ONLINE_ONLY.
    ***********************************************************/
    ALL_DEHYDRATED = 3,

    /***********************************************************
    The item and all its subitems are dehydrated and
    VfsItemAvailability.ONLINE_ONLY.

    This guarantees that contents will not take up space.
    ***********************************************************/
    ONLINE_ONLY = 4,
}

} // namespace PinStateEnums

} // namespace Occ
