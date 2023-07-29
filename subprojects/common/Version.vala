/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright LGPLv2.1 or later
***********************************************************/

namespace Occ {
namespace Common {

public class NextcloudVersion { //: GLib.Object {

    public const int MIRALL_VERSION_MAJOR = 3;
    public const int MIRALL_VERSION_MINOR = 4;
    public const int MIRALL_VERSION_PATCH = 50;
    public const int MIRALL_VERSION_YEAR = 2021;
    public const int MIRALL_SOVERSION = 0;

    /***********************************************************
    Minimum supported server version according to
    https://docs.nextcloud.com/server/latest/admin_manual/release_schedule.html
    ***********************************************************/
    public const int NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MAJOR = 16;
    public const int NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_MINOR = 0;
    public const int NEXTCLOUD_SERVER_VERSION_MIN_SUPPORTED_PATCH = 0;

    /***********************************************************
    e.g. beta1, beta2, rc1
    ***********************************************************/
    public const string MIRALL_VERSION_SUFFIX = "git";

    /***********************************************************
    Composite defines
    Used e.g. for libraries Keep at x.y.z.
    ***********************************************************/
    public const string MIRALL_VERSION = MIRALL_VERSION_MAJOR.to_string () + "." + MIRALL_VERSION_MINOR.to_string () + "." + MIRALL_VERSION_PATCH.to_string ();
    /***********************************************************
    const string MIRALL_VERSION_FULL = MIRALL_VERSION.to_string() + "." + MIRALL_VERSION_BUILD.to_string ();
    ***********************************************************/
    public const string MIRALL_VERSION_STRING = MIRALL_VERSION.to_string () + " (build " + MIRALL_VERSION_SUFFIX.to_string () + ")";

    /***********************************************************
    define MIRALL_STRINGIFY(s) MIRALL_TOSTRING(s)
    ***********************************************************/

} // class NextcloudVersion

} // namespace Common
} // namespace Occ
