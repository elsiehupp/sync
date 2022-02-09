/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QHttp_part>


//  #include <QLoggingCategory>
//  #include <QElapsedTimer>
//  #include <QHttpMultiPart>
//  #include <memory>

namespace Occ {

/***********************************************************
@brief The PutMultiFileJob class
@ingroup libsync
***********************************************************/
class PutMultiFileJob : AbstractNetworkJob {

    struct SingleUploadFileData {
        std.unique_ptr<UploadDevice> device;
        GLib.HashTable<GLib.ByteArray, GLib.ByteArray> headers;
    }


    /***********************************************************
    ***********************************************************/
    private QHttpMultiPart body;
    private GLib.List<SingleUploadFileData> devices;

    string error_string {
        public get {
            this.error_string == "" ? AbstractNetworkJob.error_string () : this.error_string;
        }
        protected set {
            this.error_string = value;
        }
    }

    private GLib.Uri url;
    private QElapsedTimer request_timer;


    signal void finished_signal ();
    signal void upload_progress (int64 value1, int64 value2);

    /***********************************************************
    ***********************************************************/
    public PutMultiFileJob.for_account (AccountPointer account, GLib.Uri url,
        GLib.List<SingleUploadFileData> devices, GLib.Object parent = new GLib.Object ()) {
        base (account, {}, parent);
        this.devices = std.move (devices);
        this.url = url;
        this.body.content_type (QHttpMultiPart.Related_type);
        foreach (var single_device in this.devices) {
            single_device.device.parent (this);
            connect (this, &PutMultiFileJob.upload_progress,
                    single_device.device.get (), &UploadDevice.on_signal_job_upload_progress);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        Soup.Request request;

        foreach (var one_device in this.devices) {
            var one_part = new QHttp_part ();

            one_part.body_device (one_device.device.get ());

            foreach (var header in one_device.headers) {
                one_part.raw_header (header.key (), header.value ());
            }

            request.priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

            this.body.append (one_part);
        }

        send_request ("POST", this.url, request, this.body);

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warning (" Network error: " + reply ().error_string ());
        }

        connect (reply (), &Soup.Reply.upload_progress, this, &PutMultiFileJob.upload_progress);
        connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);
        this.request_timer.on_signal_start ();
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        foreach (var one_device in this.devices) {
            one_device.device.close ();
        }

        GLib.info ("POST of" + reply ().request ().url ().to_string () + path () + "FINISHED WITH STATUS"
                + reply_status_string ()
                + reply ().attribute (Soup.Request.HttpStatusCodeAttribute)
                + reply ().attribute (Soup.Request.HttpReasonPhraseAttribute));

        /* emit */ finished_signal ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (this.request_timer.elapsed ());
    }

} // class PutMultiFileJob

} // namespace Occ
    