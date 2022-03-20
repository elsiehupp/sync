/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QHttp_part>


//  #include <QLoggingCategory>
//  #include <QElapsedTimer>
//  #include <QHttpMultiPart>
//  #include <memory>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The PutMultiFileJob class
@ingroup libsync
***********************************************************/
public class PutMultiFileJob : AbstractNetworkJob {

    struct SingleUploadFileData {
        std.unique_ptr<UploadDevice> device;
        GLib.HashTable<string, string> headers;
    }


    /***********************************************************
    ***********************************************************/
    private QHttpMultiPart body;
    private GLib.List<SingleUploadFileData> devices;

    new string error_string {
        public get {
            this.error_string == "" ? AbstractNetworkJob.error_string : this.error_string;
        }
        protected set {
            this.error_string = value;
        }
    }

    private GLib.Uri url;
    private QElapsedTimer request_timer;


    internal signal void signal_finished ();
    internal signal void signal_upload_progress (int64 value1, int64 value2);

    /***********************************************************
    ***********************************************************/
    public PutMultiFileJob.for_account (Account account, GLib.Uri url,
        GLib.List<SingleUploadFileData> devices, GLib.Object parent = new GLib.Object ()) {
        base (account, {}, parent);
        this.devices = std.move (devices);
        this.url = url;
        this.body.content_type (QHttpMultiPart.Related_type);
        foreach (var single_device in this.devices) {
            single_device.device.parent (this);
            this.signal_upload_progress.connect (
                single_device.device.on_signal_job_upload_progress
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();

        foreach (var one_device in this.devices) {
            var one_part = new QHttp_part ();

            one_part.body_device (one_device.device);

            foreach (var header in one_device.headers) {
                one_part.raw_header (header.key (), header.value ());
            }

            request.priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

            this.body.append (one_part);
        }

        send_request ("POST", this.url, request, this.body);

        if (this.reply.error != Soup.Reply.NoError) {
            GLib.warning (" Network error: " + this.reply.error_string);
        }

        this.reply.signal_upload_progress.connect (
            this.on_signal_upload_progress
        );
        this.signal_network_activity.connect (
            account.on_signal_propagator_network_activity
        );
        this.request_timer.start ();
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        foreach (var one_device in this.devices) {
            one_device.device.close ();
        }

        GLib.info ("POST of" + this.reply.request ().url.to_string () + this.path + " finished with status "
                + reply_status_string ()
                + this.reply.attribute (Soup.Request.HttpStatusCodeAttribute)
                + this.reply.attribute (Soup.Request.HttpReasonPhraseAttribute));

        /* emit */ signal_finished ();
        return true;
    }


    /***********************************************************
    FIXME: GLib.TimeSpan is microseconds, not milliseconds!
    ***********************************************************/
    public GLib.TimeSpan ms_since_start {
        return this.request_timer.elapsed ();
    }

} // class PutMultiFileJob

} // namespace LibSync
} // namespace Occ
    