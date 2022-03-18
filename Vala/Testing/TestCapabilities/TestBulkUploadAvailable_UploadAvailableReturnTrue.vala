

namespace Occ {
namespace Testing {

public class TestBulkUploadAvailable_UploadAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestBulkUploadAvailable_UploadAvailableReturnTrue () {
        QVariantMap bulkupload_map;
        bulkupload_map["bulkupload"] = "1.0";

        QVariantMap capabilities_map;
        capabilities_map["dav"] = bulkupload_map;

        var capabilities = Capabilities (capabilities_map);
        var bulkupload_available = capabilities.bulk_upload ();

        GLib.assert_true (bulkupload_available == true);
    }

} // class TestBulkUploadAvailable_UploadAvailableReturnTrue

} // namespace Testing
} // namespace Occ
