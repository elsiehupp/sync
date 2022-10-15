namespace Occ {
namespace Testing {

/***********************************************************
@class TestIsPathWindowsDrivePartitionRoot

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestIsPathWindowsDrivePartitionRoot : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestIsPathWindowsDrivePartitionRoot () {
        //  // should always return false on non-Windows
        //  GLib.assert_true (!is_path_windows_drive_partition_root ("c:"));
        //  GLib.assert_true (!is_path_windows_drive_partition_root ("c:/"));
        //  GLib.assert_true (!is_path_windows_drive_partition_root ("c:\\"));
    }

} // class TestIsPathWindowsDrivePartitionRoot

} // namespace Testing
} // namespace Occ
