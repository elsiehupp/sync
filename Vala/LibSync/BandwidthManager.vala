/***********************************************************
Copyright (C) by Markus Goetz <markus@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QTimer>
// #include <QTimer>
// #include <QIODevice>
// #include <list>

namespace Occ {


/***********************************************************
@brief The BandwidthManager class
@ingroup libsync
***********************************************************/
class BandwidthManager : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public BandwidthManager (OwncloudPropagator p);

    /***********************************************************
    ***********************************************************/
    public 
    public bool using_absolute_upload_limit () {
        return this.current_upload_limit > 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool using_relative_upload_limit () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    }


    /***********************************************************
    ***********************************************************/
    public urn this.current_download_limit > 0;
    }
    public bool using_relative_download_limit () {
        return this.current_download_limit < 0;
    }


    /***********************************************************
    ***********************************************************/
    public void on_register_upload_device (UploadDevice *);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_unregister_download_job (GLib.Obj

    /***********************************************************
    ***********************************************************/
    public void on_absolute_limit_timer_expire

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_relative_upload_delay_timer_expired ();

    public void on_relative_download_measuring_timer_expired ();


    public void on_relative_download_delay_timer_expired ();


    // for switching between absolute and relative bw limiting
    private QTimer this.switching_timer;

    // FIXME this timer and this variable should be replaced
    // by the propagator emitting the changed limit values to us as signal
    private OwncloudPropagator this.propagator;

    // for absolute up/down bw limiting
    private QTimer this.absolute_limit_timer;

    // FIXME merge these two lists
    private GLib.List<UploadDevice> this.absolute_upload_device_list;
    private GLib.List<UploadDevice> this.relative_upload_device_list;

    /***********************************************************
    ***********************************************************/
    private QTimer this.relative_upload_measuring_timer;

    // for relative bw limiting, we need to wait this amount before measuring again
    private QTimer this.relative_upload_delay_timer;

    // the device measured
    private UploadDevice this.relative_limit_current_measured_device;

    // for measuring how much progress we made at on_start
    private int64 this.relative_upload_limit_progress_at_measuring_restart;
    private int64 this.current_upload_limit;

    /***********************************************************
    ***********************************************************/
    private GLib.List<GETFileJob> this.download_job_list;
    private QTimer this.relative_download_measuring_timer;

    // for relative bw limiting, we need to wait this amount before measuring again
    private QTimer this.relative_download_delay_timer;

    // the device measured
    private GETFileJob this.relative_limit_current_measured_job;

    // for measuring how much progress we made at on_start
    private int64 this.relative_download_limit_progress_at_measuring_restart;

    /***********************************************************
    ***********************************************************/
    private int64 this.current_download_limit;
}

    // Because of the many layers of buffering inside Qt (and probably the OS and the network)
    // we cannot lower this value much more. If we do, the estimated bw will be very high
    // because the buffers fill fast while the actual network algorithms are not relevant yet.
    static int64 relative_limit_measuring_timer_interval_msec = 1000 * 2;
    // See also WritingState in http://code.woboq.org/qt5/qtbase/src/network/access/qhttpprotocolhandler.cpp.html#this.ZN20QHttp_protocol_handler11send_request_ev

    // FIXME At some point:
    //  * Register device only after the QNR received its meta_data_changed () signal
    //  * Incorporate Qt buffer fill state (it's a negative absolute delta).
    //  * Incorporate SSL overhead (percentage)
    //  * For relative limiting, do less measuring and more delaying+giving quota
    //  * For relative limiting, smoothen measurements

    BandwidthManager.BandwidthManager (OwncloudPropagator p)
        : GLib.Object ()
        , this.propagator (p)
        , this.relative_limit_current_measured_device (nullptr)
        , this.relative_upload_limit_progress_at_measuring_restart (0)
        , this.current_upload_limit (0)
        , this.relative_limit_current_measured_job (nullptr)
        , this.current_download_limit (0) {
        this.current_upload_limit = this.propagator._upload_limit;
        this.current_download_limit = this.propagator._download_limit;

        GLib.Object.connect (&this.switching_timer, &QTimer.timeout, this, &BandwidthManager.on_switching_timer_expired);
        this.switching_timer.set_interval (10 * 1000);
        this.switching_timer.on_start ();
        QMetaObject.invoke_method (this, "on_switching_timer_expired", Qt.QueuedConnection);

        // absolute uploads/downloads
        GLib.Object.connect (&this.absolute_limit_timer, &QTimer.timeout, this, &BandwidthManager.on_absolute_limit_timer_expired);
        this.absolute_limit_timer.set_interval (1000);
        this.absolute_limit_timer.on_start ();

        // Relative uploads
        GLib.Object.connect (&this.relative_upload_measuring_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_upload_measuring_timer_expired);
        this.relative_upload_measuring_timer.set_interval (relative_limit_measuring_timer_interval_msec);
        this.relative_upload_measuring_timer.on_start ();
        this.relative_upload_measuring_timer.set_single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&this.relative_upload_delay_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_upload_delay_timer_expired);
        this.relative_upload_delay_timer.set_single_shot (true); // will be restarted from the measuring timer

        // Relative downloads
        GLib.Object.connect (&this.relative_download_measuring_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_download_measuring_timer_expired);
        this.relative_download_measuring_timer.set_interval (relative_limit_measuring_timer_interval_msec);
        this.relative_download_measuring_timer.on_start ();
        this.relative_download_measuring_timer.set_single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&this.relative_download_delay_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_download_delay_timer_expired);
        this.relative_download_delay_timer.set_single_shot (true); // will be restarted from the measuring timer
    }

    BandwidthManager.~BandwidthManager () = default;

    void BandwidthManager.on_register_upload_device (UploadDevice p) {
        this.absolute_upload_device_list.push_back (p);
        this.relative_upload_device_list.push_back (p);
        GLib.Object.connect (p, &GLib.Object.destroyed, this, &BandwidthManager.on_unregister_upload_device);

        if (using_absolute_upload_limit ()) {
            p.set_bandwidth_limited (true);
            p.set_choked (false);
        } else if (using_relative_upload_limit ()) {
            p.set_bandwidth_limited (true);
            p.set_choked (true);
        } else {
            p.set_bandwidth_limited (false);
            p.set_choked (false);
        }
    }

    void BandwidthManager.on_unregister_upload_device (GLib.Object o) {
        var p = reinterpret_cast<UploadDevice> (o); // note, we might already be in the ~GLib.Object
        this.absolute_upload_device_list.remove (p);
        this.relative_upload_device_list.remove (p);
        if (p == this.relative_limit_current_measured_device) {
            this.relative_limit_current_measured_device = nullptr;
            this.relative_upload_limit_progress_at_measuring_restart = 0;
        }
    }

    void BandwidthManager.on_register_download_job (GETFileJob j) {
        this.download_job_list.push_back (j);
        GLib.Object.connect (j, &GLib.Object.destroyed, this, &BandwidthManager.on_unregister_download_job);

        if (using_absolute_download_limit ()) {
            j.set_bandwidth_limited (true);
            j.set_choked (false);
        } else if (using_relative_download_limit ()) {
            j.set_bandwidth_limited (true);
            j.set_choked (true);
        } else {
            j.set_bandwidth_limited (false);
            j.set_choked (false);
        }
    }

    void BandwidthManager.on_unregister_download_job (GLib.Object o) {
        var j = reinterpret_cast<GETFileJob> (o); // note, we might already be in the ~GLib.Object
        this.download_job_list.remove (j);
        if (this.relative_limit_current_measured_job == j) {
            this.relative_limit_current_measured_job = nullptr;
            this.relative_download_limit_progress_at_measuring_restart = 0;
        }
    }

    void BandwidthManager.on_relative_upload_measuring_timer_expired () {
        if (!using_relative_upload_limit () || this.relative_upload_device_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_upload_delay_timer.set_interval (1000);
            this.relative_upload_delay_timer.on_start ();
            return;
        }
        if (!this.relative_limit_current_measured_device) {
            GLib.debug (lc_bandwidth_manager) << "No device set, just waiting 1 sec";
            this.relative_upload_delay_timer.set_interval (1000);
            this.relative_upload_delay_timer.on_start ();
            return;
        }

        GLib.debug (lc_bandwidth_manager) << this.relative_upload_device_list.size () << "Starting Delay";

        int64 relative_limit_progress_measured = (this.relative_limit_current_measured_device._read_with_progress
                                                   + this.relative_limit_current_measured_device._read)
            / 2;
        int64 relative_limit_progress_difference = relative_limit_progress_measured - this.relative_upload_limit_progress_at_measuring_restart;
        GLib.debug (lc_bandwidth_manager) << this.relative_upload_limit_progress_at_measuring_restart
                                    << relative_limit_progress_measured << relative_limit_progress_difference;

        int64 speed_kb_per_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        GLib.debug (lc_bandwidth_manager) << relative_limit_progress_difference / 1024 << "k_b =>" << speed_kb_per_sec << "k_b/sec on full speed ("
                                    << this.relative_limit_current_measured_device._read_with_progress << this.relative_limit_current_measured_device._read
                                    << q_abs (this.relative_limit_current_measured_device._read_with_progress
                                           - this.relative_limit_current_measured_device._read)
                                    << ")";

        int64 upload_limit_percent = -this.current_upload_limit;
        // don't use too extreme values
        upload_limit_percent = q_min (upload_limit_percent, int64 (90));
        upload_limit_percent = q_max (int64 (10), upload_limit_percent);
        int64 whole_time_msec = (100.0 / upload_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        GLib.debug (lc_bandwidth_manager) << wait_time_msec << " - " << real_wait_time_msec << " msec for " << upload_limit_percent << "%";

        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any upload to timeout
        this.relative_upload_delay_timer.set_interval (real_wait_time_msec);
        this.relative_upload_delay_timer.on_start ();

        var device_count = this.relative_upload_device_list.size ();
        int64 quota_per_device = relative_limit_progress_difference * (upload_limit_percent / 100.0) / device_count + 1.0;
        Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
            ud.set_bandwidth_limited (true);
            ud.set_choked (false);
            ud.give_bandwidth_quota (quota_per_device);
            GLib.debug (lc_bandwidth_manager) << "Gave" << quota_per_device / 1024.0 << "k_b to" << ud;
        }
        this.relative_limit_current_measured_device = nullptr;
    }

    void BandwidthManager.on_relative_upload_delay_timer_expired () {
        // Switch to measuring state
        this.relative_upload_measuring_timer.on_start (); // always on_start to continue the cycle

        if (!using_relative_upload_limit ()) {
            return; // oh, not actually needed
        }

        if (this.relative_upload_device_list.empty ()) {
            return;
        }

        GLib.debug (lc_bandwidth_manager) << this.relative_upload_device_list.size () << "Starting measuring";

        // Take first device and then append it again (= we round robin all devices)
        this.relative_limit_current_measured_device = this.relative_upload_device_list.front ();
        this.relative_upload_device_list.pop_front ();
        this.relative_upload_device_list.push_back (this.relative_limit_current_measured_device);

        this.relative_upload_limit_progress_at_measuring_restart = (this.relative_limit_current_measured_device._read_with_progress
                                                             + this.relative_limit_current_measured_device._read)
            / 2;
        this.relative_limit_current_measured_device.set_bandwidth_limited (false);
        this.relative_limit_current_measured_device.set_choked (false);

        // choke all other UploadDevice s
        Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
            if (ud != this.relative_limit_current_measured_device) {
                ud.set_bandwidth_limited (true);
                ud.set_choked (true);
            }
        }

        // now we're in measuring state
    }

    // for downloads:
    void BandwidthManager.on_relative_download_measuring_timer_expired () {
        if (!using_relative_download_limit () || this.download_job_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_download_delay_timer.set_interval (1000);
            this.relative_download_delay_timer.on_start ();
            return;
        }
        if (!this.relative_limit_current_measured_job) {
            GLib.debug (lc_bandwidth_manager) << "No job set, just waiting 1 sec";
            this.relative_download_delay_timer.set_interval (1000);
            this.relative_download_delay_timer.on_start ();
            return;
        }

        GLib.debug (lc_bandwidth_manager) << this.download_job_list.size () << "Starting Delay";

        int64 relative_limit_progress_measured = this.relative_limit_current_measured_job.current_download_position ();
        int64 relative_limit_progress_difference = relative_limit_progress_measured - this.relative_download_limit_progress_at_measuring_restart;
        GLib.debug (lc_bandwidth_manager) << this.relative_download_limit_progress_at_measuring_restart
                                    << relative_limit_progress_measured << relative_limit_progress_difference;

        int64 speed_kb_per_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        GLib.debug (lc_bandwidth_manager) << relative_limit_progress_difference / 1024 << "k_b =>" << speed_kb_per_sec << "k_b/sec on full speed ("
                                    << this.relative_limit_current_measured_job.current_download_position ();

        int64 download_limit_percent = -this.current_download_limit;
        // don't use too extreme values
        download_limit_percent = q_min (download_limit_percent, int64 (90));
        download_limit_percent = q_max (int64 (10), download_limit_percent);
        int64 whole_time_msec = (100.0 / download_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        GLib.debug (lc_bandwidth_manager) << wait_time_msec << " - " << real_wait_time_msec << " msec for " << download_limit_percent << "%";

        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any download to timeout
        this.relative_download_delay_timer.set_interval (real_wait_time_msec);
        this.relative_download_delay_timer.on_start ();

        var job_count = this.download_job_list.size ();
        int64 quota = relative_limit_progress_difference * (download_limit_percent / 100.0);
        if (quota > 20 * 1024) {
            q_c_info (lc_bandwidth_manager) << "ADJUSTING QUOTA FROM " << quota << " TO " << quota - 20 * 1024;
            quota -= 20 * 1024;
        }
        int64 quota_per_job = quota / job_count + 1;
        Q_FOREACH (GETFileJob gfj, this.download_job_list) {
            gfj.set_bandwidth_limited (true);
            gfj.set_choked (false);
            gfj.give_bandwidth_quota (quota_per_job);
            GLib.debug (lc_bandwidth_manager) << "Gave" << quota_per_job / 1024.0 << "k_b to" << gfj;
        }
        this.relative_limit_current_measured_device = nullptr;
    }

    void BandwidthManager.on_relative_download_delay_timer_expired () {
        // Switch to measuring state
        this.relative_download_measuring_timer.on_start (); // always on_start to continue the cycle

        if (!using_relative_download_limit ()) {
            return; // oh, not actually needed
        }

        if (this.download_job_list.empty ()) {
            GLib.debug (lc_bandwidth_manager) << this.download_job_list.size () << "No jobs?";
            return;
        }

        GLib.debug (lc_bandwidth_manager) << this.download_job_list.size () << "Starting measuring";

        // Take first device and then append it again (= we round robin all devices)
        this.relative_limit_current_measured_job = this.download_job_list.front ();
        this.download_job_list.pop_front ();
        this.download_job_list.push_back (this.relative_limit_current_measured_job);

        this.relative_download_limit_progress_at_measuring_restart = this.relative_limit_current_measured_job.current_download_position ();
        this.relative_limit_current_measured_job.set_bandwidth_limited (false);
        this.relative_limit_current_measured_job.set_choked (false);

        // choke all other download jobs
        Q_FOREACH (GETFileJob gfj, this.download_job_list) {
            if (gfj != this.relative_limit_current_measured_job) {
                gfj.set_bandwidth_limited (true);
                gfj.set_choked (true);
            }
        }

        // now we're in measuring state
    }

    // end downloads

    void BandwidthManager.on_switching_timer_expired () {
        int64 new_upload_limit = this.propagator._upload_limit;
        if (new_upload_limit != this.current_upload_limit) {
            q_c_info (lc_bandwidth_manager) << "Upload Bandwidth limit changed" << this.current_upload_limit << new_upload_limit;
            this.current_upload_limit = new_upload_limit;
            Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
                if (new_upload_limit == 0) {
                    ud.set_bandwidth_limited (false);
                    ud.set_choked (false);
                } else if (new_upload_limit > 0) {
                    ud.set_bandwidth_limited (true);
                    ud.set_choked (false);
                } else if (new_upload_limit < 0) {
                    ud.set_bandwidth_limited (true);
                    ud.set_choked (true);
                }
            }
        }
        int64 new_download_limit = this.propagator._download_limit;
        if (new_download_limit != this.current_download_limit) {
            q_c_info (lc_bandwidth_manager) << "Download Bandwidth limit changed" << this.current_download_limit << new_download_limit;
            this.current_download_limit = new_download_limit;
            Q_FOREACH (GETFileJob j, this.download_job_list) {
                if (using_absolute_download_limit ()) {
                    j.set_bandwidth_limited (true);
                    j.set_choked (false);
                } else if (using_relative_download_limit ()) {
                    j.set_bandwidth_limited (true);
                    j.set_choked (true);
                } else {
                    j.set_bandwidth_limited (false);
                    j.set_choked (false);
                }
            }
        }
    }

    void BandwidthManager.on_absolute_limit_timer_expired () {
        if (using_absolute_upload_limit () && !this.absolute_upload_device_list.empty ()) {
            int64 quota_per_device = this.current_upload_limit / q_max ( (GLib.List<UploadDevice>.size_type)1, this.absolute_upload_device_list.size ());
            GLib.debug (lc_bandwidth_manager) << quota_per_device << this.absolute_upload_device_list.size () << this.current_upload_limit;
            Q_FOREACH (UploadDevice device, this.absolute_upload_device_list) {
                device.give_bandwidth_quota (quota_per_device);
                GLib.debug (lc_bandwidth_manager) << "Gave " << quota_per_device / 1024.0 << " k_b to" << device;
            }
        }
        if (using_absolute_download_limit () && !this.download_job_list.empty ()) {
            int64 quota_per_job = this.current_download_limit / q_max ( (GLib.List<GETFileJob>.size_type)1, this.download_job_list.size ());
            GLib.debug (lc_bandwidth_manager) << quota_per_job << this.download_job_list.size () << this.current_download_limit;
            Q_FOREACH (GETFileJob j, this.download_job_list) {
                j.give_bandwidth_quota (quota_per_job);
                GLib.debug (lc_bandwidth_manager) << "Gave " << quota_per_job / 1024.0 << " k_b to" << j;
            }
        }
    }

    } // namespace Occ
    