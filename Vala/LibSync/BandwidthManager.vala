/***********************************************************
@author Markus Goetz <markus@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <QLoggingCategory>
//  #include <GLib.Timeout>
//  #include <QIODevice>
//  #include <list>

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The BandwidthManager class
@ingroup libsync
***********************************************************/
public class BandwidthManager : GLib.Object {

    /***********************************************************
    For switching between absolute and relative bw limiting
    ***********************************************************/
    private GLib.Timeout switching_timer;

    /***********************************************************
    FIXME this timer and this variable should be replaced by the
    propagator emitting the changed limit values to us as signal
    ***********************************************************/
    private OwncloudPropagator propagator;

    /***********************************************************
    For absolute up/down bw limiting
    ***********************************************************/
    private GLib.Timeout absolute_limit_timer;

    /***********************************************************
    FIXME merge these two lists
    ***********************************************************/
    private GLib.List<UploadDevice> absolute_upload_device_list;
    private GLib.List<UploadDevice> relative_upload_device_list;

    /***********************************************************
    ***********************************************************/
    private GLib.Timeout relative_upload_measuring_timer;

    /***********************************************************
    For relative bandwidth limiting, we need to wait this amount
    before measuring again
    ***********************************************************/
    private GLib.Timeout relative_upload_delay_timer;

    /***********************************************************
    The device measured
    ***********************************************************/
    private UploadDevice relative_limit_current_measured_device;

    /***********************************************************
    For measuring how much progress we made at start
    ***********************************************************/
    private int64 relative_upload_limit_progress_at_measuring_restart;
    private int64 current_upload_limit;

    /***********************************************************
    ***********************************************************/
    private GLib.List<GETFileJob> download_job_list;
    private GLib.Timeout relative_download_measuring_timer;

    /***********************************************************
    For relative bandwidth limiting, we need to wait this amount
    before measuring again
    ***********************************************************/
    private GLib.Timeout relative_download_delay_timer;

    /***********************************************************
    The device measured
    ***********************************************************/
    private GETFileJob relative_limit_current_measured_job;

    /***********************************************************
    For measuring how much progress we made at start
    ***********************************************************/
    private int64 relative_download_limit_progress_at_measuring_restart;

    /***********************************************************
    ***********************************************************/
    private int64 current_download_limit;

    /***********************************************************
    Because of the many layers of buffering inside Qt (and probably the OS and the network)
    we cannot lower this value much more. If we do, the estimated bw will be very high
    because the buffers fill fast while the actual network algorithms are not relevant yet.
    See also WritingState in http://code.woboq.org/qt5/qtbase/src/network/access/qhttpprotocolhandler.cpp.html#ZN20QHttp_protocol_handler11send_request_ev
    ***********************************************************/
    private static int64 relative_limit_measuring_timer_interval_msec = 1000 * 2;

    /***********************************************************
    FIXME At some point:
     * Register device only after the QNR received its meta_data_changed () signal
     * Incorporate Qt buffer fill state (it's a negative absolute delta).
     * Incorporate SSL overhead (percentage)
     * For relative limiting, do less measuring and more delaying+giving quota
     * For relative limiting, smoothen measurements
    ***********************************************************/
    public BandwidthManager (OwncloudPropagator upload_propagator) {
        base ();
        this.propagator = upload_propagator;
        this.relative_limit_current_measured_device = null;
        this.relative_upload_limit_progress_at_measuring_restart = 0;
        this.current_upload_limit = 0;
        this.relative_limit_current_measured_job = null;
        this.current_download_limit = 0;
        this.current_upload_limit = this.propagator.upload_limit;
        this.current_download_limit = this.propagator.download_limit;

        this.switching_timer.timeout.connect (
            this.on_signal_switching_timer_timeout
        );
        this.switching_timer.interval (10 * 1000);
        this.switching_timer.start ();
        QMetaObject.invoke_method (this, "on_signal_switching_timer_timeout", Qt.QueuedConnection);

        // absolute uploads/downloads
        this.absolute_limit_timer.timeout.connect (
            this.on_signal_absolute_limit_timer_timeout
        );
        this.absolute_limit_timer.interval (1000);
        this.absolute_limit_timer.start ();

        // Relative uploads
        this.relative_upload_measuring_timer.timeout.connect (
            this.on_signal_relative_upload_measuring_timer_timeout
        );
        this.relative_upload_measuring_timer.interval (relative_limit_measuring_timer_interval_msec);
        this.relative_upload_measuring_timer.start ();
        this.relative_upload_measuring_timer.single_shot (true); // will be restarted from the delay timer
        this.relative_upload_delay_timer.timeout.connect (
            this, BandwidthManager.on_signal_relative_upload_delay_timer_timeout
        );
        this.relative_upload_delay_timer.single_shot (true); // will be restarted from the measuring timer

        // Relative downloads
        this.relative_download_measuring_timer.timeout.connect (
            this.on_signal_relative_download_measuring_timer_timeout
        );
        this.relative_download_measuring_timer.interval (relative_limit_measuring_timer_interval_msec);
        this.relative_download_measuring_timer.start ();
        this.relative_download_measuring_timer.single_shot (true); // will be restarted from the delay timer
        this.relative_download_delay_timer.timeout.connect (
            this.on_signal_relative_download_delay_timer_timeout
        );
        this.relative_download_delay_timer.single_shot (true); // will be restarted from the measuring timer
    }


    /***********************************************************
    ***********************************************************/
    public bool using_absolute_upload_limit {
        public get {
            return this.current_upload_limit > 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool using_relative_upload_limit {
        public get {
            return this.current_upload_limit < 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool using_absolute_download_limit {
        public get {
            return this.current_download_limit > 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool using_relative_download_limit {
        public get {
            return this.current_download_limit < 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_register_upload_device (UploadDevice upload_device) {
        this.absolute_upload_device_list.push_back (upload_device);
        this.relative_upload_device_list.push_back (upload_device);
        upload_device.destroyed.connect (
            this.on_signal_unregister_upload_device
        );

        if (this.using_absolute_upload_limit) {
            upload_device.bandwidth_limited = true;
            upload_device.choked = false;
        } else if (this.using_relative_upload_limit) {
            upload_device.bandwidth_limited = true;
            upload_device.choked = true;
        } else {
            upload_device.bandwidth_limited = false;
            upload_device.choked = false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_unregister_upload_device (GLib.Object o) {
        var upload_device = reinterpret_cast<UploadDevice> (o); // note, we might already be in the ~GLib.Object
        this.absolute_upload_device_list.remove (upload_device);
        this.relative_upload_device_list.remove (upload_device);
        if (upload_device == this.relative_limit_current_measured_device) {
            this.relative_limit_current_measured_device = null;
            this.relative_upload_limit_progress_at_measuring_restart = 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_register_download_job (GETFileJob get_file_job) {
        this.download_job_list.push_back (get_file_job);
        get_file_job.destroyed.connect (
            this.on_signal_unregister_download_job
        );

        if (this.using_absolute_download_limit) {
            get_file_job.bandwidth_limited = true;
            get_file_job.choked = false;
        } else if (this.using_relative_download_limit) {
            get_file_job.bandwidth_limited = true;
            get_file_job.choked = true;
        } else {
            get_file_job.bandwidth_limited = false;
            get_file_job.choked = false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_relative_upload_measuring_timer_timeout () {
        if (!this.using_relative_upload_limit || this.relative_upload_device_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_upload_delay_timer.interval (1000);
            this.relative_upload_delay_timer.start ();
            return;
        }
        if (!this.relative_limit_current_measured_device) {
            GLib.debug ("No device set, just waiting 1 sec");
            this.relative_upload_delay_timer.interval (1000);
            this.relative_upload_delay_timer.start ();
            return;
        }

        GLib.debug (this.relative_upload_device_list.size () + "Starting Delay");

        int64 relative_limit_progress_measured = (this.relative_limit_current_measured_device.read_with_progress
                                                   + this.relative_limit_current_measured_device.read)
            / 2;
        int64 relative_limit_progress_difference = relative_limit_progress_measured - this.relative_upload_limit_progress_at_measuring_restart;
        GLib.debug (this.relative_upload_limit_progress_at_measuring_restart
                    + relative_limit_progress_measured
                    + relative_limit_progress_difference);

        int64 speed_kb_per_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        GLib.debug (relative_limit_progress_difference / 1024 + "k_b =>"
                    + speed_kb_per_sec + "k_b/sec on full speed ("
                    + this.relative_limit_current_measured_device.read_with_progress
                    + this.relative_limit_current_measured_device.read
                    + q_abs (this.relative_limit_current_measured_device.read_with_progress
                            - this.relative_limit_current_measured_device.read)
                    + ")");

        int64 upload_limit_percent = -this.current_upload_limit;
        // don't use too extreme values
        upload_limit_percent = q_min (upload_limit_percent, int64 (90));
        upload_limit_percent = q_max (int64 (10), upload_limit_percent);
        int64 whole_time_msec = (100.0 / upload_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        GLib.debug (wait_time_msec + " - " + real_wait_time_msec + " msec for " + upload_limit_percent + "%");

        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any upload to timeout
        this.relative_upload_delay_timer.interval (real_wait_time_msec);
        this.relative_upload_delay_timer.start ();

        var device_count = this.relative_upload_device_list.size ();
        int64 quota_per_device = relative_limit_progress_difference * (upload_limit_percent / 100.0) / device_count + 1.0;
        foreach (UploadDevice upload_device in this.relative_upload_device_list) {
            upload_device.bandwidth_limited = true;
            upload_device.choked = false;
            upload_device.give_bandwidth_quota (quota_per_device);
            GLib.debug ("Gave" + quota_per_device / 1024.0 + "k_b to" + upload_device);
        }
        this.relative_limit_current_measured_device = null;
    }


    /***********************************************************
    ***********************************************************/
    public void BandwidthManager.on_signal_unregister_download_job (GLib.Object o) {
        var get_file_job = reinterpret_cast<GETFileJob> (o); // note, we might already be in the ~GLib.Object
        this.download_job_list.remove (get_file_job);
        if (this.relative_limit_current_measured_job == get_file_job) {
            this.relative_limit_current_measured_job = null;
            this.relative_download_limit_progress_at_measuring_restart = 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_absolute_limit_timer_timeout () {
        if (this.using_absolute_upload_limit && !this.absolute_upload_device_list.empty ()) {
            int64 quota_per_device = this.current_upload_limit / q_max ( 1, this.absolute_upload_device_list.size ());
            GLib.debug (quota_per_device + this.absolute_upload_device_list.size () + this.current_upload_limit);
            foreach (UploadDevice device in this.absolute_upload_device_list) {
                device.give_bandwidth_quota (quota_per_device);
                GLib.debug ("Gave " + quota_per_device / 1024.0 + " kB to" + device);
            }
        }
        if (this.using_absolute_download_limit && !this.download_job_list.empty ()) {
            int64 quota_per_job = this.current_download_limit / q_max ( 1, this.download_job_list.size ());
            GLib.debug (quota_per_job + this.download_job_list.size () + this.current_download_limit);
            foreach (GETFileJob get_file_job in this.download_job_list) {
                get_file_job.give_bandwidth_quota (quota_per_job);
                GLib.debug ("Gave " + quota_per_job / 1024.0 + " k_b to" + get_file_job);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_switching_timer_timeout () {
        int64 new_upload_limit = this.propagator.upload_limit;
        if (new_upload_limit != this.current_upload_limit) {
            GLib.info ("Upload Bandwidth limit changed " + this.current_upload_limit.to_string () + new_upload_limit.to_string ());
            this.current_upload_limit = new_upload_limit;
            foreach (UploadDevice upload_device in this.relative_upload_device_list) {
                if (new_upload_limit == 0) {
                    upload_device.bandwidth_limited = false;
                    upload_device.choked = false;
                } else if (new_upload_limit > 0) {
                    upload_device.bandwidth_limited = true;
                    upload_device.choked = false;
                } else if (new_upload_limit < 0) {
                    upload_device.bandwidth_limited = true;
                    upload_device.choked = true;
                }
            }
        }
        int64 new_download_limit = this.propagator.download_limit;
        if (new_download_limit != this.current_download_limit) {
            GLib.info ("Download Bandwidth limit changed " + this.current_download_limit.to_string () + new_download_limit.to_string ());
            this.current_download_limit = new_download_limit;
            foreach (GETFileJob get_file_job in this.download_job_list) {
                if (this.using_absolute_download_limit) {
                    get_file_job.bandwidth_limited = true;
                    get_file_job.choked = false;
                } else if (this.using_relative_download_limit) {
                    get_file_job.bandwidth_limited = true;
                    get_file_job.choked = true;
                } else {
                    get_file_job.bandwidth_limited = false;
                    get_file_job.choked = false;
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_relative_upload_delay_timer_timeout () {
        // Switch to measuring state
        this.relative_upload_measuring_timer.start (); // always start to continue the cycle

        if (!this.using_relative_upload_limit) {
            return; // oh, not actually needed
        }

        if (this.relative_upload_device_list.empty ()) {
            return;
        }

        GLib.debug (this.relative_upload_device_list.size () + " Starting measuring");

        // Take first device and then append it again (= we round robin all devices)
        this.relative_limit_current_measured_device = this.relative_upload_device_list.front ();
        this.relative_upload_device_list.pop_front ();
        this.relative_upload_device_list.push_back (this.relative_limit_current_measured_device);

        this.relative_upload_limit_progress_at_measuring_restart =
            (this.relative_limit_current_measured_device.read_with_progress
                + this.relative_limit_current_measured_device.read)
            / 2;
        this.relative_limit_current_measured_device.bandwidth_limited = false;
        this.relative_limit_current_measured_device.choked = false;

        // choke all other UploadDevice instances
        foreach (UploadDevice upload_device in this.relative_upload_device_list) {
            if (upload_device != this.relative_limit_current_measured_device) {
                upload_device.bandwidth_limited = true;
                upload_device.choked = true;
            }
        }

        // now we're in measuring state
    }


    /***********************************************************
    // for downloads:
    ***********************************************************/
    public void on_signal_relative_download_measuring_timer_timeout () {
        if (!this.using_relative_download_limit || this.download_job_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_download_delay_timer.interval (1000);
            this.relative_download_delay_timer.start ();
            return;
        }
        if (!this.relative_limit_current_measured_job) {
            GLib.debug ("No job set, just waiting 1 sec.");
            this.relative_download_delay_timer.interval (1000);
            this.relative_download_delay_timer.start ();
            return;
        }

        GLib.debug (this.download_job_list.size () + " Starting Delay");

        int64 relative_limit_progress_measured = this.relative_limit_current_measured_job.current_download_position ();
        int64 relative_limit_progress_difference = relative_limit_progress_measured - this.relative_download_limit_progress_at_measuring_restart;
        GLib.debug (this.relative_download_limit_progress_at_measuring_restart
            + relative_limit_progress_measured + relative_limit_progress_difference);

        int64 speed_kb_per_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        GLib.debug (relative_limit_progress_difference / 1024 + "k_b =>" + speed_kb_per_sec + "kB/sec on full speed ("
            + this.relative_limit_current_measured_job.current_download_position ());

        int64 download_limit_percent = -this.current_download_limit;
        // don't use too extreme values
        download_limit_percent = q_min (download_limit_percent, int64 (90));
        download_limit_percent = q_max (int64 (10), download_limit_percent);
        int64 whole_time_msec = (100.0 / download_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        GLib.debug (wait_time_msec + " - " + real_wait_time_msec + " msec for " + download_limit_percent + "%");

        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any download to timeout
        this.relative_download_delay_timer.interval (real_wait_time_msec);
        this.relative_download_delay_timer.start ();

        var job_count = this.download_job_list.size ();
        int64 quota = relative_limit_progress_difference * (download_limit_percent / 100.0);
        if (quota > 20 * 1024) {
            GLib.info ("ADJUSTING QUOTA FROM " + quota + " TO " + quota - 20 * 1024);
            quota -= 20 * 1024;
        }
        int64 quota_per_job = quota / job_count + 1;
        foreach (GETFileJob get_file_job in this.download_job_list) {
            get_file_job.bandwidth_limited = true;
            get_file_job.choked = false;
            get_file_job.give_bandwidth_quota (quota_per_job);
            GLib.debug ("Gave" + quota_per_job / 1024.0 + "kB to " + get_file_job);
        }
        this.relative_limit_current_measured_device = null;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_relative_download_delay_timer_timeout () {
        // Switch to measuring state
        this.relative_download_measuring_timer.start (); // always start to continue the cycle

        if (!this.using_relative_download_limit) {
            return; // oh, not actually needed
        }

        if (this.download_job_list.empty ()) {
            GLib.debug (this.download_job_list.size () + " No jobs?");
            return;
        }

        GLib.debug (this.download_job_list.size () + " Starting measuring");

        // Take first device and then append it again (= we round robin all devices)
        this.relative_limit_current_measured_job = this.download_job_list.front ();
        this.download_job_list.pop_front ();
        this.download_job_list.push_back (this.relative_limit_current_measured_job);

        this.relative_download_limit_progress_at_measuring_restart = this.relative_limit_current_measured_job.current_download_position ();
        this.relative_limit_current_measured_job.bandwidth_limited = false;
        this.relative_limit_current_measured_job.choked = false;

        // choke all other download jobs
        foreach (GETFileJob get_file_job in this.download_job_list) {
            if (get_file_job != this.relative_limit_current_measured_job) {
                get_file_job.bandwidth_limited = true;
                get_file_job.choked = true;
            }
        }

        // now we're in measuring state
    }

} // class BandwidthManager

} // namespace LibSync
} // namespace Occ
    