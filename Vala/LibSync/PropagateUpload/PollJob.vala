/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief This job implements the asynchronous PUT

If the server replies
replies with an etag.
@ingroup libsync
***********************************************************/
public class PollJob : AbstractNetworkJob {

    SyncJournalDb journal;
    string local_path;

    /***********************************************************
    ***********************************************************/
    public SyncFileItemPtr item;

    signal void signal_finished ();

    /***********************************************************
    Takes ownership of the device
    ***********************************************************/
    public PollJob.for_account (unowned Account account, string path, SyncFileItemPtr item,
        SyncJournalDb journal, string local_path, GLib.Object parent) {
        base (account, path, parent);
        this.journal = journal;
        this.local_path = local_path;
        this.item = item;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        on_signal_timeout (120 * 1000);
        GLib.Uri account_url = account ().url ();
        GLib.Uri final_url = GLib.Uri.from_user_input (account_url.scheme () + QLatin1String ("://") + account_url.authority ()
            + (path ().starts_with ('/') ? QLatin1String ("") : QLatin1String ("/")) + path ());
        send_request ("GET", final_url);
        connect (reply (), Soup.Reply.download_progress, this, AbstractNetworkJob.on_signal_reset_timeout, Qt.UniqueConnection);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        Soup.Reply.NetworkError err = reply ().error ();
        if (err != Soup.Reply.NoError) {
            this.item.http_error_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
            this.item.request_id = request_id ();
            this.item.status = classify_error (err, this.item.http_error_code);
            this.item.error_string = error_string ();

            if (this.item.status == SyncFileItem.Status.FATAL_ERROR || this.item.http_error_code >= 400) {
                if (this.item.status != SyncFileItem.Status.FATAL_ERROR
                    && this.item.http_error_code != 503) {
                    SyncJournalDb.PollInfo info;
                    info.file = this.item.file;
                    // no info.url removes it from the database
                    this.journal.poll_info (info);
                    this.journal.commit ("remove poll info");
                }
                /* emit */ signal_finished ();
                return true;
            }
            QTimer.single_shot (8 * 1000, this, PollJob.on_signal_start);
            return false;
        }

        GLib.ByteArray json_data = reply ().read_all ().trimmed ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, json_parse_error).object ();
        GLib.info ("> " + json_data + " <" + reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int () + json + json_parse_error.error_string ());
        if (json_parse_error.error != QJsonParseError.NoError) {
            this.item.error_string = _("Invalid JSON reply from the poll URL");
            this.item.status = SyncFileItem.Status.NORMAL_ERROR;
            /* emit */ signal_finished ();
            return true;
        }

        var status = json["status"].to_string ();
        if (status == QLatin1String ("on_signal_init") || status == QLatin1String ("started")) {
            QTimer.single_shot (5 * 1000, this, PollJob.on_signal_start);
            return false;
        }

        this.item.response_time_stamp = response_timestamp ();
        this.item.http_error_code = json["error_code"].to_int ();

        if (status == QLatin1String ("on_signal_finished")) {
            this.item.status = SyncFileItem.Status.SUCCESS;
            this.item.file_id = json["file_identifier"].to_string ().to_utf8 ();
            this.item.etag = parse_etag (json["ETag"].to_string ().to_utf8 ());
        } else { // error
            this.item.status = classify_error (Soup.Reply.Unknown_content_error, this.item.http_error_code);
            this.item.error_string = json["error_message"].to_string ();
        }

        SyncJournalDb.PollInfo info;
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
