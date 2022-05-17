
namespace Testing {

public class FakeDeleteReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public FakeDeleteReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request, GLib.Object parent) {
        base (parent);
        set_request (request);
        set_url (request.url);
        set_operation (operation);
        open (GLib.IODevice.ReadOnly);

        string filename = get_file_path_from_url (request.url);
        GLib.assert_true (!filename == "");
        remote_root_file_info.remove (filename);
        GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    public void respond () {
        set_attribute (Soup.Request.HttpStatusCodeAttribute, 204);
        /* emit */ signal_meta_data_changed ();
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        return false; // only run once
    }

    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char char_value, int64 int64_value) {
        return 0;
    }

} // class FakeDeleteReply
} // namespace Testinh
