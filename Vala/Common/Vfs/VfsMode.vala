namespace Occ {
namespace Common {

/***********************************************************
@enum VfsMode


@brief The kind of VFS in use (or no-VFS)

@details Currently plugins and modes are one-to-one but
that's not required.

@author Christian Kamm <mail@ckamm.de>
@author Dominik Schmidt <dschmidt@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
/***********************************************************
***********************************************************/
public enum VfsMode {
    OFF,
    WITH_SUFFIX,
    WINDOWS_CF_API,
    XATTR;

    /***********************************************************
    Note: Strings are used for config and must be stable
    ***********************************************************/
    public static string to_string (VfsMode mode) {
        switch (mode) {
        case OFF:
            return "off";
        case WITH_SUFFIX:
            return "suffix";
        case WINDOWS_CF_API:
            return "wincfapi";
        case XATTR:
            return "xattr";
        }
        return "off";
    }


    /***********************************************************
    ***********************************************************/
    public static VfsMode from_string (string string_value) throws InvalidParameterError {
        // Note: Strings are used for config and must be stable

        if (string_value == "off") {
            return VfsMode.OFF;
        } else if (string_value == "suffix") {
            return VfsMode.WITH_SUFFIX;
        } else if (string_value == "wincfapi") {
            return VfsMode.WINDOWS_CF_API;
        }
        throw new InvalidParameterError.INVALID_VALUE (string_value + " is not a valid AbstractVfs VfsMode");
    }


    public static string to_plugin_name (VfsMode mode) throws InvalidParameterError {
        switch (mode) {
        case VfsMode.WITH_SUFFIX:
            return "suffix";
        case VfsMode.WINDOWS_CF_API:
            return "cfapi";
        case VfsMode.XATTR:
            return "xattr";
        }
        throw new InvalidParameterError.INVALID_VALUE (VfsMode.to_string (mode) + " is not a valid AbstractVfs VfsMode");
    }
}
