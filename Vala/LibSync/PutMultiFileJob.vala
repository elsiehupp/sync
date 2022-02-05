/***********************************************************
Copyright 2021 (c) Matthieu Gallien <matthieu.gallien@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QHttp_part>

//  #pragma once

//  #include <QLoggingCategory>
//  #include <QElapsedTimer>
//  #include <QHttpMultiPart>
//  #include <memory>

//  Q_DECLARE_LOGGING_CATEGORY (lc_put_multi_file_job)

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
        this.body.set_content_type (QHttpMultiPart.Related_type);
        for (var single_device : this.devices) {
            single_device.device.set_parent (this);
            connect (this, &PutMultiFileJob.upload_progress,
                    single_device.device.get (), &UploadDevice.on_job_upload_progress);
        }
    }

    ~PutMultiFileJob () = default;

    /***********************************************************
    ***********************************************************/
    public void on_start () {
        Soup.Request req;

        for (var one_device : this.devices) {
            var one_part = QHttp_part{};

            one_part.set_body_device (one_device.device.get ());

            for (GLib.HashMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = one_device.headers.begin (); it != one_device.headers.end (); ++it) {
                one_part.set_raw_header (it.key (), it.value ());
            }

            req.set_priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

            this.body.append (one_part);
        }

        send_request ("POST", this.url, req, this.body);

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (lc_put_multi_file_job) << " Network error : " << reply ().error_string ();
        }

        connect (reply (), &Soup.Reply.upload_progress, this, &PutMultiFileJob.upload_progress);
        connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);
        this.request_timer.on_start ();
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_finished () {
        for (var one_device : this.devices) {
            one_device.device.close ();
        }

        GLib.info (lc_put_multi_file_job) << "POST of" << reply ().request ().url ().to_string () << path () << "FINISHED WITH STATUS"
                         << reply_status_string ()
                         << reply ().attribute (Soup.Request.HttpStatusCodeAttribute)
                         << reply ().attribute (Soup.Request.HttpReasonPhraseAttribute);

        /* emit */ finished_signal ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () override {
        return this.error_string.is_empty () ? AbstractNetworkJob.error_string () : this.error_string;
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (this.request_timer.elapsed ());
    }

} // class PutMultiFileJob

} // namespace Occ
    