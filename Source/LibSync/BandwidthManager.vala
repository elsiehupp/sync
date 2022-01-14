/***********************************************************
Copyright (C) by Markus Goetz <markus@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QTimer>
// #include <GLib.Object>

// #include <GLib.Object>
// #include <QTimer>
// #include <QIODevice>
// #include <list>

namespace Occ {


/***********************************************************
@brief The Bandwidth_manager class
@ingroup libsync
***********************************************************/
class Bandwidth_manager : GLib.Object {
public:
    Bandwidth_manager (Owncloud_propagator *p);
    ~Bandwidth_manager () override;

    bool using_absolute_upload_limit () { return _current_upload_limit > 0; }
    bool using_relative_upload_limit () { return _current_upload_limit < 0; }
    bool using_absolute_download_limit () { return _current_download_limit > 0; }
    bool using_relative_download_limit () { return _current_download_limit < 0; }

public slots:
    void register_upload_device (Upload_device *);
    void unregister_upload_device (GLib.Object *);

    void register_download_job (GETFile_job *);
    void unregister_download_job (GLib.Object *);

    void absolute_limit_timer_expired ();
    void switching_timer_expired ();

    void relative_upload_measuring_timer_expired ();
    void relative_upload_delay_timer_expired ();

    void relative_download_measuring_timer_expired ();
    void relative_download_delay_timer_expired ();

private:
    // for switching between absolute and relative bw limiting
    QTimer _switching_timer;

    // FIXME this timer and this variable should be replaced
    // by the propagator emitting the changed limit values to us as signal
    Owncloud_propagator *_propagator;

    // for absolute up/down bw limiting
    QTimer _absolute_limit_timer;

    // FIXME merge these two lists
    std.list<Upload_device> _absolute_upload_device_list;
    std.list<Upload_device> _relative_upload_device_list;

    QTimer _relative_upload_measuring_timer;

    // for relative bw limiting, we need to wait this amount before measuring again
    QTimer _relative_upload_delay_timer;

    // the device measured
    Upload_device *_relative_limit_current_measured_device;

    // for measuring how much progress we made at start
    int64 _relative_upload_limit_progress_at_measuring_restart;
    int64 _current_upload_limit;

    std.list<GETFile_job> _download_job_list;
    QTimer _relative_download_measuring_timer;

    // for relative bw limiting, we need to wait this amount before measuring again
    QTimer _relative_download_delay_timer;

    // the device measured
    GETFile_job *_relative_limit_current_measured_job;

    // for measuring how much progress we made at start
    int64 _relative_download_limit_progress_at_measuring_restart;

    int64 _current_download_limit;
};

    // Because of the many layers of buffering inside Qt (and probably the OS and the network)
    // we cannot lower this value much more. If we do, the estimated bw will be very high
    // because the buffers fill fast while the actual network algorithms are not relevant yet.
    static int64 relative_limit_measuring_timer_interval_msec = 1000 * 2;
    // See also Writing_state in http://code.woboq.org/qt5/qtbase/src/network/access/qhttpprotocolhandler.cpp.html#_ZN20QHttp_protocol_handler11send_request_ev
    
    // FIXME At some point:
    //  * Register device only after the QNR received its meta_data_changed () signal
    //  * Incorporate Qt buffer fill state (it's a negative absolute delta).
    //  * Incorporate SSL overhead (percentage)
    //  * For relative limiting, do less measuring and more delaying+giving quota
    //  * For relative limiting, smoothen measurements
    
    Bandwidth_manager.Bandwidth_manager (Owncloud_propagator *p)
        : GLib.Object ()
        , _propagator (p)
        , _relative_limit_current_measured_device (nullptr)
        , _relative_upload_limit_progress_at_measuring_restart (0)
        , _current_upload_limit (0)
        , _relative_limit_current_measured_job (nullptr)
        , _current_download_limit (0) {
        _current_upload_limit = _propagator._upload_limit;
        _current_download_limit = _propagator._download_limit;
    
        GLib.Object.connect (&_switching_timer, &QTimer.timeout, this, &Bandwidth_manager.switching_timer_expired);
        _switching_timer.set_interval (10 * 1000);
        _switching_timer.start ();
        QMetaObject.invoke_method (this, "switching_timer_expired", Qt.QueuedConnection);
    
        // absolute uploads/downloads
        GLib.Object.connect (&_absolute_limit_timer, &QTimer.timeout, this, &Bandwidth_manager.absolute_limit_timer_expired);
        _absolute_limit_timer.set_interval (1000);
        _absolute_limit_timer.start ();
    
        // Relative uploads
        GLib.Object.connect (&_relative_upload_measuring_timer, &QTimer.timeout,
            this, &Bandwidth_manager.relative_upload_measuring_timer_expired);
        _relative_upload_measuring_timer.set_interval (relative_limit_measuring_timer_interval_msec);
        _relative_upload_measuring_timer.start ();
        _relative_upload_measuring_timer.set_single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&_relative_upload_delay_timer, &QTimer.timeout,
            this, &Bandwidth_manager.relative_upload_delay_timer_expired);
        _relative_upload_delay_timer.set_single_shot (true); // will be restarted from the measuring timer
    
        // Relative downloads
        GLib.Object.connect (&_relative_download_measuring_timer, &QTimer.timeout,
            this, &Bandwidth_manager.relative_download_measuring_timer_expired);
        _relative_download_measuring_timer.set_interval (relative_limit_measuring_timer_interval_msec);
        _relative_download_measuring_timer.start ();
        _relative_download_measuring_timer.set_single_shot (true); // will be restarted from the delay timer
        GLib.Object.connect (&_relative_download_delay_timer, &QTimer.timeout,
            this, &Bandwidth_manager.relative_download_delay_timer_expired);
        _relative_download_delay_timer.set_single_shot (true); // will be restarted from the measuring timer
    }
    
    Bandwidth_manager.~Bandwidth_manager () = default;
    
    void Bandwidth_manager.register_upload_device (Upload_device *p) {
        _absolute_upload_device_list.push_back (p);
        _relative_upload_device_list.push_back (p);
        GLib.Object.connect (p, &GLib.Object.destroyed, this, &Bandwidth_manager.unregister_upload_device);
    
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
    
    void Bandwidth_manager.unregister_upload_device (GLib.Object *o) {
        auto p = reinterpret_cast<Upload_device> (o); // note, we might already be in the ~GLib.Object
        _absolute_upload_device_list.remove (p);
        _relative_upload_device_list.remove (p);
        if (p == _relative_limit_current_measured_device) {
            _relative_limit_current_measured_device = nullptr;
            _relative_upload_limit_progress_at_measuring_restart = 0;
        }
    }
    
    void Bandwidth_manager.register_download_job (GETFile_job *j) {
        _download_job_list.push_back (j);
        GLib.Object.connect (j, &GLib.Object.destroyed, this, &Bandwidth_manager.unregister_download_job);
    
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
    
    void Bandwidth_manager.unregister_download_job (GLib.Object *o) {
        auto *j = reinterpret_cast<GETFile_job> (o); // note, we might already be in the ~GLib.Object
        _download_job_list.remove (j);
        if (_relative_limit_current_measured_job == j) {
            _relative_limit_current_measured_job = nullptr;
            _relative_download_limit_progress_at_measuring_restart = 0;
        }
    }
    
    void Bandwidth_manager.relative_upload_measuring_timer_expired () {
        if (!using_relative_upload_limit () || _relative_upload_device_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            _relative_upload_delay_timer.set_interval (1000);
            _relative_upload_delay_timer.start ();
            return;
        }
        if (!_relative_limit_current_measured_device) {
            q_c_debug (lc_bandwidth_manager) << "No device set, just waiting 1 sec";
            _relative_upload_delay_timer.set_interval (1000);
            _relative_upload_delay_timer.start ();
            return;
        }
    
        q_c_debug (lc_bandwidth_manager) << _relative_upload_device_list.size () << "Starting Delay";
    
        int64 relative_limit_progress_measured = (_relative_limit_current_measured_device._read_with_progress
                                                   + _relative_limit_current_measured_device._read)
            / 2;
        int64 relative_limit_progress_difference = relative_limit_progress_measured - _relative_upload_limit_progress_at_measuring_restart;
        q_c_debug (lc_bandwidth_manager) << _relative_upload_limit_progress_at_measuring_restart
                                    << relative_limit_progress_measured << relative_limit_progress_difference;
    
        int64 speedk_bPer_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        q_c_debug (lc_bandwidth_manager) << relative_limit_progress_difference / 1024 << "k_b =>" << speedk_bPer_sec << "k_b/sec on full speed ("
                                    << _relative_limit_current_measured_device._read_with_progress << _relative_limit_current_measured_device._read
                                    << q_abs (_relative_limit_current_measured_device._read_with_progress
                                           - _relative_limit_current_measured_device._read)
                                    << ")";
    
        int64 upload_limit_percent = -_current_upload_limit;
        // don't use too extreme values
        upload_limit_percent = q_min (upload_limit_percent, int64 (90));
        upload_limit_percent = q_max (int64 (10), upload_limit_percent);
        int64 whole_time_msec = (100.0 / upload_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        q_c_debug (lc_bandwidth_manager) << wait_time_msec << " - " << real_wait_time_msec << " msec for " << upload_limit_percent << "%";
    
        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any upload to timeout
        _relative_upload_delay_timer.set_interval (real_wait_time_msec);
        _relative_upload_delay_timer.start ();
    
        auto device_count = _relative_upload_device_list.size ();
        int64 quota_per_device = relative_limit_progress_difference * (upload_limit_percent / 100.0) / device_count + 1.0;
        Q_FOREACH (Upload_device *ud, _relative_upload_device_list) {
            ud.set_bandwidth_limited (true);
            ud.set_choked (false);
            ud.give_bandwidth_quota (quota_per_device);
            q_c_debug (lc_bandwidth_manager) << "Gave" << quota_per_device / 1024.0 << "k_b to" << ud;
        }
        _relative_limit_current_measured_device = nullptr;
    }
    
    void Bandwidth_manager.relative_upload_delay_timer_expired () {
        // Switch to measuring state
        _relative_upload_measuring_timer.start (); // always start to continue the cycle
    
        if (!using_relative_upload_limit ()) {
            return; // oh, not actually needed
        }
    
        if (_relative_upload_device_list.empty ()) {
            return;
        }
    
        q_c_debug (lc_bandwidth_manager) << _relative_upload_device_list.size () << "Starting measuring";
    
        // Take first device and then append it again (= we round robin all devices)
        _relative_limit_current_measured_device = _relative_upload_device_list.front ();
        _relative_upload_device_list.pop_front ();
        _relative_upload_device_list.push_back (_relative_limit_current_measured_device);
    
        _relative_upload_limit_progress_at_measuring_restart = (_relative_limit_current_measured_device._read_with_progress
                                                             + _relative_limit_current_measured_device._read)
            / 2;
        _relative_limit_current_measured_device.set_bandwidth_limited (false);
        _relative_limit_current_measured_device.set_choked (false);
    
        // choke all other Upload_devices
        Q_FOREACH (Upload_device *ud, _relative_upload_device_list) {
            if (ud != _relative_limit_current_measured_device) {
                ud.set_bandwidth_limited (true);
                ud.set_choked (true);
            }
        }
    
        // now we're in measuring state
    }
    
    // for downloads:
    void Bandwidth_manager.relative_download_measuring_timer_expired () {
        if (!using_relative_download_limit () || _download_job_list.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            _relative_download_delay_timer.set_interval (1000);
            _relative_download_delay_timer.start ();
            return;
        }
        if (!_relative_limit_current_measured_job) {
            q_c_debug (lc_bandwidth_manager) << "No job set, just waiting 1 sec";
            _relative_download_delay_timer.set_interval (1000);
            _relative_download_delay_timer.start ();
            return;
        }
    
        q_c_debug (lc_bandwidth_manager) << _download_job_list.size () << "Starting Delay";
    
        int64 relative_limit_progress_measured = _relative_limit_current_measured_job.current_download_position ();
        int64 relative_limit_progress_difference = relative_limit_progress_measured - _relative_download_limit_progress_at_measuring_restart;
        q_c_debug (lc_bandwidth_manager) << _relative_download_limit_progress_at_measuring_restart
                                    << relative_limit_progress_measured << relative_limit_progress_difference;
    
        int64 speedk_bPer_sec = (relative_limit_progress_difference / relative_limit_measuring_timer_interval_msec * 1000) / 1024;
        q_c_debug (lc_bandwidth_manager) << relative_limit_progress_difference / 1024 << "k_b =>" << speedk_bPer_sec << "k_b/sec on full speed ("
                                    << _relative_limit_current_measured_job.current_download_position ();
    
        int64 download_limit_percent = -_current_download_limit;
        // don't use too extreme values
        download_limit_percent = q_min (download_limit_percent, int64 (90));
        download_limit_percent = q_max (int64 (10), download_limit_percent);
        int64 whole_time_msec = (100.0 / download_limit_percent) * relative_limit_measuring_timer_interval_msec;
        int64 wait_time_msec = whole_time_msec - relative_limit_measuring_timer_interval_msec;
        int64 real_wait_time_msec = wait_time_msec + whole_time_msec;
        q_c_debug (lc_bandwidth_manager) << wait_time_msec << " - " << real_wait_time_msec << " msec for " << download_limit_percent << "%";
    
        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any download to timeout
        _relative_download_delay_timer.set_interval (real_wait_time_msec);
        _relative_download_delay_timer.start ();
    
        auto job_count = _download_job_list.size ();
        int64 quota = relative_limit_progress_difference * (download_limit_percent / 100.0);
        if (quota > 20 * 1024) {
            q_c_info (lc_bandwidth_manager) << "ADJUSTING QUOTA FROM " << quota << " TO " << quota - 20 * 1024;
            quota -= 20 * 1024;
        }
        int64 quota_per_job = quota / job_count + 1;
        Q_FOREACH (GETFile_job *gfj, _download_job_list) {
            gfj.set_bandwidth_limited (true);
            gfj.set_choked (false);
            gfj.give_bandwidth_quota (quota_per_job);
            q_c_debug (lc_bandwidth_manager) << "Gave" << quota_per_job / 1024.0 << "k_b to" << gfj;
        }
        _relative_limit_current_measured_device = nullptr;
    }
    
    void Bandwidth_manager.relative_download_delay_timer_expired () {
        // Switch to measuring state
        _relative_download_measuring_timer.start (); // always start to continue the cycle
    
        if (!using_relative_download_limit ()) {
            return; // oh, not actually needed
        }
    
        if (_download_job_list.empty ()) {
            q_c_debug (lc_bandwidth_manager) << _download_job_list.size () << "No jobs?";
            return;
        }
    
        q_c_debug (lc_bandwidth_manager) << _download_job_list.size () << "Starting measuring";
    
        // Take first device and then append it again (= we round robin all devices)
        _relative_limit_current_measured_job = _download_job_list.front ();
        _download_job_list.pop_front ();
        _download_job_list.push_back (_relative_limit_current_measured_job);
    
        _relative_download_limit_progress_at_measuring_restart = _relative_limit_current_measured_job.current_download_position ();
        _relative_limit_current_measured_job.set_bandwidth_limited (false);
        _relative_limit_current_measured_job.set_choked (false);
    
        // choke all other download jobs
        Q_FOREACH (GETFile_job *gfj, _download_job_list) {
            if (gfj != _relative_limit_current_measured_job) {
                gfj.set_bandwidth_limited (true);
                gfj.set_choked (true);
            }
        }
    
        // now we're in measuring state
    }
    
    // end downloads
    
    void Bandwidth_manager.switching_timer_expired () {
        int64 new_upload_limit = _propagator._upload_limit;
        if (new_upload_limit != _current_upload_limit) {
            q_c_info (lc_bandwidth_manager) << "Upload Bandwidth limit changed" << _current_upload_limit << new_upload_limit;
            _current_upload_limit = new_upload_limit;
            Q_FOREACH (Upload_device *ud, _relative_upload_device_list) {
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
        int64 new_download_limit = _propagator._download_limit;
        if (new_download_limit != _current_download_limit) {
            q_c_info (lc_bandwidth_manager) << "Download Bandwidth limit changed" << _current_download_limit << new_download_limit;
            _current_download_limit = new_download_limit;
            Q_FOREACH (GETFile_job *j, _download_job_list) {
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
    
    void Bandwidth_manager.absolute_limit_timer_expired () {
        if (using_absolute_upload_limit () && !_absolute_upload_device_list.empty ()) {
            int64 quota_per_device = _current_upload_limit / q_max ( (std.list<Upload_device>.size_type)1, _absolute_upload_device_list.size ());
            q_c_debug (lc_bandwidth_manager) << quota_per_device << _absolute_upload_device_list.size () << _current_upload_limit;
            Q_FOREACH (Upload_device *device, _absolute_upload_device_list) {
                device.give_bandwidth_quota (quota_per_device);
                q_c_debug (lc_bandwidth_manager) << "Gave " << quota_per_device / 1024.0 << " k_b to" << device;
            }
        }
        if (using_absolute_download_limit () && !_download_job_list.empty ()) {
            int64 quota_per_job = _current_download_limit / q_max ( (std.list<GETFile_job>.size_type)1, _download_job_list.size ());
            q_c_debug (lc_bandwidth_manager) << quota_per_job << _download_job_list.size () << _current_download_limit;
            Q_FOREACH (GETFile_job *j, _download_job_list) {
                j.give_bandwidth_quota (quota_per_job);
                q_c_debug (lc_bandwidth_manager) << "Gave " << quota_per_job / 1024.0 << " k_b to" << j;
            }
        }
    }
    
    } // namespace Occ
    