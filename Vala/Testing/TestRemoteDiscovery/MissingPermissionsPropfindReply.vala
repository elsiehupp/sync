namespace Occ {
namespace Testing {

/***********************************************************
@class MissingPermissionsPropfindReply

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class MissingPermissionsPropfindReply : FakePropfindReply {

    MissingPermissionsPropfindReply (FileInfo remote_root_file_info, Soup.Operation operation,
        Soup.Request request, GLib.Object parent) {
        base (remote_root_file_info, operation, request, parent);
        // If the propfind contains a single file without permissions, this is a server error
        const string to_remove = "<oc:permissions>RDNVCKW</oc:permissions>";
        var position = payload.index_of (to_remove, payload.size ()/2);
        GLib.assert_true (position > 0);
        payload.remove (position, sizeof (to_remove) - 1);
    }

} // class MissingPermissionsPropfindReply

} // namespace Testing
} // namespace Occ

