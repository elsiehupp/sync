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
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers;
    }


    /***********************************************************
    ***********************************************************/
    private QHttpMultiPart body;
    private GLib.Vector<SingleUploadFileData> devices;
    private string error_string;
    private GLib.Uri url;
    private QElapsedTimer request_timer;


    signal void finished_signal ();
    signal void upload_progress (int64, int64);

    /***********************************************************
    ***********************************************************/
    public PutMultiFileJob (AccountPointer account, GLib.Uri url,
        GLib.Vector<SingleUploadFileData> devices, GLib.Object parent = new GLib.Object ()) {
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

    ~PutMultiFileJob () = default;

    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        Soup.Request reques;

        foreach (var one_device in this.devices) {
            var one_part = QHttp_part{};

            one_part.body_device (one_device.device.get ());

            for (GLib.HashMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = one_device.headers.begin (); it != one_device.headers.end (); ++it) {
                one_part.raw_header (it.key (), it.value ());
            }

            reques.priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

            this.body.append (one_part);
        }

        send_request ("POST", this.url, reques, this.body);

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (" Network error : " + reply ().error_string ();
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

        GLib.info ("POST of" + reply ().request ().url ().to_string () + path ("FINISHED WITH STATUS"
                         + reply_status_string ()
                         + reply ().attribute (Soup.Request.HttpStatusCodeAttribute)
                         + reply ().attribute (Soup.Request.HttpReasonPhraseAttribute);

        /* emit */ finished_signal ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () {
        return this.error_string.is_empty () ? AbstractNetworkJob.error_string () : this.error_string;
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (this.request_timer.elapsed ());
    }

} // class PutMultiFileJob

} // namespace Occ
    