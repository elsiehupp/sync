/***********************************************************
Copyright (C) by Markus Goetz <markus@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QTimer>
//  #include <QTimer>
//  #include <QIODevice>
//  #include <list>

namespace Occ {

/***********************************************************
@brief The BandwidthManager class
@ingroup libsync
***********************************************************/
class BandwidthManager : GLib.Object {

    /***********************************************************
    For switching between absolute and relative bw limiting
    ***********************************************************/
    private QTimer switching_timer;

    /***********************************************************
    FIXME this timer and this variable should be replaced by the
    propagator emitting the changed limit values to us as signal
    ***********************************************************/
    private OwncloudPropagator propagator;

    /***********************************************************
    For absolute up/down bw limiting
    ***********************************************************/
    private QTimer absolute_limit_timer;

    /***********************************************************
    FIXME merge these two lists
    ***********************************************************/
    private GLib.List<UploadDevice> absolute_upload_device_list;
    private GLib.List<UploadDevice> relative_upload_device_list;

    /***********************************************************
    ***********************************************************/
    private QTimer relative_upload_measuring_timer;

    /***********************************************************
    For relative bandwidth limiting, we need to wait this amount
    before measuring again
    ***********************************************************/
    private QTimer relative_upload_delay_timer;

    /***********************************************************
    The device measured
    ***********************************************************/
    private UploadDevice relative_limit_current_measured_device;

    /***********************************************************
    For measuring how much progress we made at on_start
    ***********************************************************/
    private int64 relative_upload_limit_progress_at_measuring_restart;
    private int64 current_upload_limit;

    /***********************************************************
    ***********************************************************/
    private GLib.List<GETFileJob> download_job_list;
    private QTimer relative_download_measuring_timer;

    /***********************************************************
    For relative bandwidth limiting, we need to wait this amount
    before measuring again
    ***********************************************************/
    private QTimer relative_download_delay_timer;

    /***********************************************************
    The device measured
    ***********************************************************/
    private GETFileJob relative_limit_current_measured_job;

    /***********************************************************
    For measuring how much progress we made at on_start
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
    static int64 relative_limit_measuring_timer_interval_msec = 1000 * 2;

    /***********************************************************
    FIXME At some point:
     * Register device only after the QNR received its meta_data_changed () signal
     * Incorporate Qt buffer fill state (it's a negative absolute delta).
     * Incorporate SSL overhead (percentage)
     * For relative limiting, do less measuring and more delaying+giving quota
     * For relative limiting, smoothen measurements
    ***********************************************************/
    public BandwidthManager (OwncloudPropagator p) {
        base ();
        this.propagator = p;
        this.relative_limit_current_measured_device = null;
        this.relative_upload_limit_progress_at_measuring_restart = 0;
        this.current_upload_limit = 0;
        this.relative_limit_current_measured_job = null;
        this.current_download_limit = 0;
        this.current_upload_limit = this.propagator.upload_limit;
        this.current_download_limit = this.propagator.download_limit;

        GLib.Object.connect (&this.switching_timer, &QTimer.timeout, this, &BandwidthManager.on_switching_timer_expired);
        this.switching_timer.interval (10 * 1000);
        this.switching_timer.on_start ();
        QMetaObject.invoke_method (this, "on_switching_timer_expired", Qt.QueuedConnection);

        // absolute uploads/downloads
        GLib.Object.connect (&this.absolute_limit_timer, &QTimer.timeout, this, &BandwidthManager.on_absolute_limit_timer_expired);
        this.absolute_limit_timer.interval (1000);
        this.absolute_limit_timer.on_start ();

        // Relative uploads
        GLib.Object.connect (&this.relative_upload_measuring_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_upload_measuring_timer_expired);
        this.relative_upload_measuring_timer.interval (relative_limit_measuring_timer_interval_msec);
        this.relative_upload_measuring_timer.on_start ();
        this.relative_upload_measuring_timer.single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&this.relative_upload_delay_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_upload_delay_timer_expired);
        this.relative_upload_delay_timer.single_shot (true); // will be restarted from the measuring timer

        // Relative downloads
        GLib.Object.connect (&this.relative_download_measuring_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_download_measuring_timer_expired);
        this.relative_download_measuring_timer.interval (relative_limit_measuring_timer_interval_msec);
        this.relative_download_measuring_timer.on_start ();
        this.relative_download_measuring_timer.single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&this.relative_download_delay_timer, &QTimer.timeout,
            this, &BandwidthManager.on_relative_download_delay_timer_expired);
        this.relative_download_delay_timer.single_shot (true); // will be restarted from the measuring timer
    }


    /***********************************************************
    ***********************************************************/
    public bool using_absolute_upload_limit () {
        return this.current_upload_limit > 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool using_relative_upload_limit () {
        return this.current_upload_limit < 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool using_absolute_download_limit () {
        return this.current_download_limit > 0;
    }


    /***********************************************************
    ***********************************************************/
    public bool using_relative_download_limit () {
        return this.current_download_limit < 0;
    }


    /***********************************************************
    ***********************************************************/
    public void on_register_upload_device (UploadDevice p) {
        this.absolute_upload_device_list.push_back (p);
        this.relative_upload_device_list.push_back (p);
        GLib.Object.connect (p, &GLib.Object.destroyed, this, &BandwidthManager.on_unregister_upload_device);

        if (using_absolute_upload_limit ()) {
            p.bandwidth_limited (true);
            p.choked (false);
        } else if (using_relative_upload_limit ()) {
            p.bandwidth_limited (true);
            p.choked (true);
        } else {
            p.bandwidth_limited (false);
            p.choked (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_unregister_upload_device (GLib.Object o) {
        var p = reinterpret_cast<UploadDevice> (o); // note, we might already be in the ~GLib.Object
        this.absolute_upload_device_list.remove (p);
        this.relative_upload_device_list.remove (p);
        if (p == this.relative_limit_current_measured_device) {
            this.relative_limit_current_measured_device = null;
            this.relative_upload_limit_progress_at_measuring_restart = 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_register_download_job (GETFileJob j) {
        this.download_job_list.push_back (j);
        GLib.Object.connect (j, &GLib.Object.destroyed, this, &BandwidthManager.on_unregister_download_job);

        if (using_absolute_download_limit ()) {
            j.bandwidth_limited (true);
            j.choked (false);
        } else if (using_relative_download_limit ()) {
            j.bandwidth_limited (true);
            j.choked (true);
        } else {
            j.bandwidth_limited (false);
            j.choked (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_relative_upload_measuring_timer_expired () {
        if (!using_relative_upload_limit () || this.relative_upload_device_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_upload_delay_timer.interval (1000);
            this.relative_upload_delay_timer.on_start ();
            return;
        }
        if (!this.relative_limit_current_measured_device) {
            GLib.debug (lc_bandwidth_manager) << "No device set, just waiting 1 sec";
            this.relative_upload_delay_timer.interval (1000);
            this.relative_upload_delay_timer.on_start ();
            return;
        }

        GLib.debug (lc_bandwidth_manager) << this.relative_upload_device_list.size () << "Starting Delay";

        int64 relative_limit_progress_measured = (this.relative_limit_current_measured_device.read_with_progress
                                                   + this.relative_limit_current_measured_device.read)
            / 2;
        int64 relative_limit_progress_difference = relative_limit_progress_measured - this.relative_upload_limit_progress_at_measuring_restart;
        GLib.debug (lc_bandwidth_manager) << this.relative_upload_limit_progress_at_measuring_restart
                                    << relative_limit_progress_measured << relative_limit_progress_difference;

        int64 speed_kb_per_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        GLib.debug (lc_bandwidth_manager) << relative_limit_progress_difference / 1024 << "k_b =>" << speed_kb_per_sec << "k_b/sec on full speed ("
                                    << this.relative_limit_current_measured_device.read_with_progress << this.relative_limit_current_measured_device.read
                                    << q_abs (this.relative_limit_current_measured_device.read_with_progress
                                           - this.relative_limit_current_measured_device.read)
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
        this.relative_upload_delay_timer.interval (real_wait_time_msec);
        this.relative_upload_delay_timer.on_start ();

        var device_count = this.relative_upload_device_list.size ();
        int64 quota_per_device = relative_limit_progress_difference * (upload_limit_percent / 100.0) / device_count + 1.0;
        Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
            ud.bandwidth_limited (true);
            ud.choked (false);
            ud.give_bandwidth_quota (quota_per_device);
            GLib.debug (lc_bandwidth_manager) << "Gave" << quota_per_device / 1024.0 << "k_b to" << ud;
        }
        this.relative_limit_current_measured_device = null;
    }


    /***********************************************************
    ***********************************************************/
    public void BandwidthManager.on_unregister_download_job (GLib.Object o) {
        var j = reinterpret_cast<GETFileJob> (o); // note, we might already be in the ~GLib.Object
        this.download_job_list.remove (j);
        if (this.relative_limit_current_measured_job == j) {
            this.relative_limit_current_measured_job = null;
            this.relative_download_limit_progress_at_measuring_restart = 0;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_absolute_limit_timer_expired () {
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


    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_switching_timer_expired () {
        int64 new_upload_limit = this.propagator.upload_limit;
        if (new_upload_limit != this.current_upload_limit) {
            GLib.info (lc_bandwidth_manager) << "Upload Bandwidth limit changed" << this.current_upload_limit << new_upload_limit;
            this.current_upload_limit = new_upload_limit;
            Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
                if (new_upload_limit == 0) {
                    ud.bandwidth_limited (false);
                    ud.choked (false);
                } else if (new_upload_limit > 0) {
                    ud.bandwidth_limited (true);
                    ud.choked (false);
                } else if (new_upload_limit < 0) {
                    ud.bandwidth_limited (true);
                    ud.choked (true);
                }
            }
        }
        int64 new_download_limit = this.propagator.download_limit;
        if (new_download_limit != this.current_download_limit) {
            GLib.info (lc_bandwidth_manager) << "Download Bandwidth limit changed" << this.current_download_limit << new_download_limit;
            this.current_download_limit = new_download_limit;
            Q_FOREACH (GETFileJob j, this.download_job_list) {
                if (using_absolute_download_limit ()) {
                    j.bandwidth_limited (true);
                    j.choked (false);
                } else if (using_relative_download_limit ()) {
                    j.bandwidth_limited (true);
                    j.choked (true);
                } else {
                    j.bandwidth_limited (false);
                    j.choked (false);
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_relative_upload_delay_timer_expired () {
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

        this.relative_upload_limit_progress_at_measuring_restart = (this.relative_limit_current_measured_device.read_with_progress
                                                             + this.relative_limit_current_measured_device.read)
            / 2;
        this.relative_limit_current_measured_device.bandwidth_limited (false);
        this.relative_limit_current_measured_device.choked (false);

        // choke all other UploadDevice s
        Q_FOREACH (UploadDevice ud, this.relative_upload_device_list) {
            if (ud != this.relative_limit_current_measured_device) {
                ud.bandwidth_limited (true);
                ud.choked (true);
            }
        }

        // now we're in measuring state
    }


    /***********************************************************
    // for downloads:
    ***********************************************************/
    public void on_relative_download_measuring_timer_expired () () {
        if (!using_relative_download_limit () || this.download_job_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            this.relative_download_delay_timer.interval (1000);
            this.relative_download_delay_timer.on_start ();
            return;
        }
        if (!this.relative_limit_current_measured_job) {
            GLib.debug (lc_bandwidth_manager) << "No job set, just waiting 1 sec";
            this.relative_download_delay_timer.interval (1000);
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
        this.relative_download_delay_timer.interval (real_wait_time_msec);
        this.relative_download_delay_timer.on_start ();

        var job_count = this.download_job_list.size ();
        int64 quota = relative_limit_progress_difference * (download_limit_percent / 100.0);
        if (quota > 20 * 1024) {
            GLib.info (lc_bandwidth_manager) << "ADJUSTING QUOTA FROM " << quota << " TO " << quota - 20 * 1024;
            quota -= 20 * 1024;
        }
        int64 quota_per_job = quota / job_count + 1;
        Q_FOREACH (GETFileJob gfj, this.download_job_list) {
            gfj.bandwidth_limited (true);
            gfj.choked (false);
            gfj.give_bandwidth_quota (quota_per_job);
            GLib.debug (lc_bandwidth_manager) << "Gave" << quota_per_job / 1024.0 << "k_b to" << gfj;
        }
        this.relative_limit_current_measured_device = null;
    }


    /***********************************************************
    ***********************************************************/
    public void on_relative_download_delay_timer_expired () {
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
        this.relative_limit_current_measured_job.bandwidth_limited (false);
        this.relative_limit_current_measured_job.choked (false);

        // choke all other download jobs
        Q_FOREACH (GETFileJob gfj, this.download_job_list) {
            if (gfj != this.relative_limit_current_measured_job) {
                gfj.bandwidth_limited (true);
                gfj.choked (true);
            }
        }

        // now we're in measuring state
    }
} // class BandwidthManager

} // namespace Occ
    