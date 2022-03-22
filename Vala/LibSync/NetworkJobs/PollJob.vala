namespace Occ {
namespace LibSync {

/***********************************************************
@class PollJob

@brief This job implements the asynchronous PUT

@details If the server replies replies with an etag.

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PollJob : AbstractNetworkJob {

    Common.SyncJournalDb journal;
    string local_path;

    /***********************************************************
    ***********************************************************/
    public unowned SyncFileItem item;

    internal signal void signal_finished ();

    /***********************************************************
    Takes ownership of the device
    ***********************************************************/
    public PollJob.for_account (Account account, string path, SyncFileItem item,
        Common.SyncJournalDb journal, string local_path, GLib.Object parent) {
        base (account, path, parent);
        this.journal = journal;
        this.local_path = local_path;
        this.item = item;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        on_signal_timeout (120 * 1000);
        GLib.Uri account_url = account.url;
        GLib.Uri final_url = GLib.Uri.from_user_input (account_url.scheme () + "://" + account_url.authority ()
            + (path.has_prefix ("/") ? "" : "/") + this.path);
        send_request ("GET", final_url);
        this.input_stream.download_progress.connect (
            this.on_signal_reset_timeout // Qt.UniqueConnection
        );
        base.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        GLib.InputStream.NetworkError err = this.input_stream.error;
        if (err != GLib.InputStream.NoError) {
            this.item.http_error_code = this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            this.item.request_id = request_id ();
            this.item.status = classify_error (err, this.item.http_error_code);
            this.item.error_string = this.error_string;

            if (this.item.status == SyncFileItem.Status.FATAL_ERROR || this.item.http_error_code >= 400) {
                if (this.item.status != SyncFileItem.Status.FATAL_ERROR
                    && this.item.http_error_code != 503) {
                    Common.SyncJournalDb.PollInfo info;
                    info.file = this.item.file;
                    // no info.url removes it from the database
                    this.journal.poll_info (info);
                    this.journal.commit ("remove poll info");
                }
                /* emit */ signal_finished ();
                return true;
            }
            GLib.Timeout.single_shot (8 * 1000, this, PollJob.start);
            return false;
        }

        string json_data = this.input_stream.read_all ().trimmed ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        GLib.info ("> " + json_data + " <" + this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int () + json + json_parse_error.error_string);
        if (json_parse_error.error != QJsonParseError.NoError) {
            this.item.error_string = _("Invalid JSON input_stream from the poll URL");
            this.item.status = SyncFileItem.Status.NORMAL_ERROR;
            /* emit */ signal_finished ();
            return true;
        }

        var status = json["status"].to_string ();
        if (status == "on_signal_init" || status == "started") {
            GLib.Timeout.single_shot (5 * 1000, this, PollJob.start);
            return false;
        }

        this.item.response_time_stamp = response_timestamp;
        this.item.http_error_code = json["error_code"].to_int ();

        if (status == "on_signal_finished") {
            this.item.status = SyncFileItem.Status.SUCCESS;
            this.item.file_id = json["file_identifier"].to_string ().to_utf8 ();
            this.item.etag = parse_etag (json["ETag"].to_string ().to_utf8 ());
        } else { // error
            this.item.status = classify_error (GLib.InputStream.Unknown_content_error, this.item.http_error_code);
            this.item.error_string = json["error_message"].to_string ();
        }

        Common.SyncJournalDb.PollInfo info;
        info.file = this.item.file;
        // no info.url removes it from the database
        this.journal.poll_info (info);
        this.journal.commit ("remove poll info");

        /* emit */ signal_finished ();
        return true;
    }

} // class PollJob

} // namespace LibSync
} // namespace Occ
