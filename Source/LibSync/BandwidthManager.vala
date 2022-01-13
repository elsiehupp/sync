/***********************************************************
Copyright (C) by Markus Goetz <markus@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QTimer>
// #include <QIODevice>
// #include <list>

namespace Occ {


/***********************************************************
@brief The BandwidthManager class
@ingroup libsync
***********************************************************/
class BandwidthManager : GLib.Object {
public:
    BandwidthManager (OwncloudPropagator *p);
    ~BandwidthManager () override;

    bool usingAbsoluteUploadLimit () { return _currentUploadLimit > 0; }
    bool usingRelativeUploadLimit () { return _currentUploadLimit < 0; }
    bool usingAbsoluteDownloadLimit () { return _currentDownloadLimit > 0; }
    bool usingRelativeDownloadLimit () { return _currentDownloadLimit < 0; }

public slots:
    void registerUploadDevice (UploadDevice *);
    void unregisterUploadDevice (GLib.Object *);

    void registerDownloadJob (GETFileJob *);
    void unregisterDownloadJob (GLib.Object *);

    void absoluteLimitTimerExpired ();
    void switchingTimerExpired ();

    void relativeUploadMeasuringTimerExpired ();
    void relativeUploadDelayTimerExpired ();

    void relativeDownloadMeasuringTimerExpired ();
    void relativeDownloadDelayTimerExpired ();

private:
    // for switching between absolute and relative bw limiting
    QTimer _switchingTimer;

    // FIXME this timer and this variable should be replaced
    // by the propagator emitting the changed limit values to us as signal
    OwncloudPropagator *_propagator;

    // for absolute up/down bw limiting
    QTimer _absoluteLimitTimer;

    // FIXME merge these two lists
    std.list<UploadDevice> _absoluteUploadDeviceList;
    std.list<UploadDevice> _relativeUploadDeviceList;

    QTimer _relativeUploadMeasuringTimer;

    // for relative bw limiting, we need to wait this amount before measuring again
    QTimer _relativeUploadDelayTimer;

    // the device measured
    UploadDevice *_relativeLimitCurrentMeasuredDevice;

    // for measuring how much progress we made at start
    int64 _relativeUploadLimitProgressAtMeasuringRestart;
    int64 _currentUploadLimit;

    std.list<GETFileJob> _downloadJobList;
    QTimer _relativeDownloadMeasuringTimer;

    // for relative bw limiting, we need to wait this amount before measuring again
    QTimer _relativeDownloadDelayTimer;

    // the device measured
    GETFileJob *_relativeLimitCurrentMeasuredJob;

    // for measuring how much progress we made at start
    int64 _relativeDownloadLimitProgressAtMeasuringRestart;

    int64 _currentDownloadLimit;
};

} // namespace Occ

#endif










/***********************************************************
Copyright (C) by Markus Goetz <markus@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QTimer>
// #include <GLib.Object>

namespace Occ {

    Q_LOGGING_CATEGORY (lcBandwidthManager, "nextcloud.sync.bandwidthmanager", QtInfoMsg)
    
    // Because of the many layers of buffering inside Qt (and probably the OS and the network)
    // we cannot lower this value much more. If we do, the estimated bw will be very high
    // because the buffers fill fast while the actual network algorithms are not relevant yet.
    static int64 relativeLimitMeasuringTimerIntervalMsec = 1000 * 2;
    // See also WritingState in http://code.woboq.org/qt5/qtbase/src/network/access/qhttpprotocolhandler.cpp.html#_ZN20QHttpProtocolHandler11sendRequestEv
    
    // FIXME At some point:
    //  * Register device only after the QNR received its metaDataChanged () signal
    //  * Incorporate Qt buffer fill state (it's a negative absolute delta).
    //  * Incorporate SSL overhead (percentage)
    //  * For relative limiting, do less measuring and more delaying+giving quota
    //  * For relative limiting, smoothen measurements
    
    BandwidthManager.BandwidthManager (OwncloudPropagator *p)
        : GLib.Object ()
        , _propagator (p)
        , _relativeLimitCurrentMeasuredDevice (nullptr)
        , _relativeUploadLimitProgressAtMeasuringRestart (0)
        , _currentUploadLimit (0)
        , _relativeLimitCurrentMeasuredJob (nullptr)
        , _currentDownloadLimit (0) {
        _currentUploadLimit = _propagator._uploadLimit;
        _currentDownloadLimit = _propagator._downloadLimit;
    
        GLib.Object.connect (&_switchingTimer, &QTimer.timeout, this, &BandwidthManager.switchingTimerExpired);
        _switchingTimer.setInterval (10 * 1000);
        _switchingTimer.start ();
        QMetaObject.invokeMethod (this, "switchingTimerExpired", Qt.QueuedConnection);
    
        // absolute uploads/downloads
        GLib.Object.connect (&_absoluteLimitTimer, &QTimer.timeout, this, &BandwidthManager.absoluteLimitTimerExpired);
        _absoluteLimitTimer.setInterval (1000);
        _absoluteLimitTimer.start ();
    
        // Relative uploads
        GLib.Object.connect (&_relativeUploadMeasuringTimer, &QTimer.timeout,
            this, &BandwidthManager.relativeUploadMeasuringTimerExpired);
        _relativeUploadMeasuringTimer.setInterval (relativeLimitMeasuringTimerIntervalMsec);
        _relativeUploadMeasuringTimer.start ();
        _relativeUploadMeasuringTimer.setSingleShot (true); // will be restarted from the delay timer
        GLib.Object.connect (&_relativeUploadDelayTimer, &QTimer.timeout,
            this, &BandwidthManager.relativeUploadDelayTimerExpired);
        _relativeUploadDelayTimer.setSingleShot (true); // will be restarted from the measuring timer
    
        // Relative downloads
        GLib.Object.connect (&_relativeDownloadMeasuringTimer, &QTimer.timeout,
            this, &BandwidthManager.relativeDownloadMeasuringTimerExpired);
        _relativeDownloadMeasuringTimer.setInterval (relativeLimitMeasuringTimerIntervalMsec);
        _relativeDownloadMeasuringTimer.start ();
        _relativeDownloadMeasuringTimer.setSingleShot (true); // will be restarted from the delay timer
        GLib.Object.connect (&_relativeDownloadDelayTimer, &QTimer.timeout,
            this, &BandwidthManager.relativeDownloadDelayTimerExpired);
        _relativeDownloadDelayTimer.setSingleShot (true); // will be restarted from the measuring timer
    }
    
    BandwidthManager.~BandwidthManager () = default;
    
    void BandwidthManager.registerUploadDevice (UploadDevice *p) {
        _absoluteUploadDeviceList.push_back (p);
        _relativeUploadDeviceList.push_back (p);
        GLib.Object.connect (p, &GLib.Object.destroyed, this, &BandwidthManager.unregisterUploadDevice);
    
        if (usingAbsoluteUploadLimit ()) {
            p.setBandwidthLimited (true);
            p.setChoked (false);
        } else if (usingRelativeUploadLimit ()) {
            p.setBandwidthLimited (true);
            p.setChoked (true);
        } else {
            p.setBandwidthLimited (false);
            p.setChoked (false);
        }
    }
    
    void BandwidthManager.unregisterUploadDevice (GLib.Object *o) {
        auto p = reinterpret_cast<UploadDevice> (o); // note, we might already be in the ~GLib.Object
        _absoluteUploadDeviceList.remove (p);
        _relativeUploadDeviceList.remove (p);
        if (p == _relativeLimitCurrentMeasuredDevice) {
            _relativeLimitCurrentMeasuredDevice = nullptr;
            _relativeUploadLimitProgressAtMeasuringRestart = 0;
        }
    }
    
    void BandwidthManager.registerDownloadJob (GETFileJob *j) {
        _downloadJobList.push_back (j);
        GLib.Object.connect (j, &GLib.Object.destroyed, this, &BandwidthManager.unregisterDownloadJob);
    
        if (usingAbsoluteDownloadLimit ()) {
            j.setBandwidthLimited (true);
            j.setChoked (false);
        } else if (usingRelativeDownloadLimit ()) {
            j.setBandwidthLimited (true);
            j.setChoked (true);
        } else {
            j.setBandwidthLimited (false);
            j.setChoked (false);
        }
    }
    
    void BandwidthManager.unregisterDownloadJob (GLib.Object *o) {
        auto *j = reinterpret_cast<GETFileJob> (o); // note, we might already be in the ~GLib.Object
        _downloadJobList.remove (j);
        if (_relativeLimitCurrentMeasuredJob == j) {
            _relativeLimitCurrentMeasuredJob = nullptr;
            _relativeDownloadLimitProgressAtMeasuringRestart = 0;
        }
    }
    
    void BandwidthManager.relativeUploadMeasuringTimerExpired () {
        if (!usingRelativeUploadLimit () || _relativeUploadDeviceList.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            _relativeUploadDelayTimer.setInterval (1000);
            _relativeUploadDelayTimer.start ();
            return;
        }
        if (!_relativeLimitCurrentMeasuredDevice) {
            qCDebug (lcBandwidthManager) << "No device set, just waiting 1 sec";
            _relativeUploadDelayTimer.setInterval (1000);
            _relativeUploadDelayTimer.start ();
            return;
        }
    
        qCDebug (lcBandwidthManager) << _relativeUploadDeviceList.size () << "Starting Delay";
    
        int64 relativeLimitProgressMeasured = (_relativeLimitCurrentMeasuredDevice._readWithProgress
                                                   + _relativeLimitCurrentMeasuredDevice._read)
            / 2;
        int64 relativeLimitProgressDifference = relativeLimitProgressMeasured - _relativeUploadLimitProgressAtMeasuringRestart;
        qCDebug (lcBandwidthManager) << _relativeUploadLimitProgressAtMeasuringRestart
                                    << relativeLimitProgressMeasured << relativeLimitProgressDifference;
    
        int64 speedkBPerSec = (relativeLimitProgressDifference / relativeLimitMeasuringTimerIntervalMsec * 1000) / 1024;
        qCDebug (lcBandwidthManager) << relativeLimitProgressDifference / 1024 << "kB =>" << speedkBPerSec << "kB/sec on full speed ("
                                    << _relativeLimitCurrentMeasuredDevice._readWithProgress << _relativeLimitCurrentMeasuredDevice._read
                                    << qAbs (_relativeLimitCurrentMeasuredDevice._readWithProgress
                                           - _relativeLimitCurrentMeasuredDevice._read)
                                    << ")";
    
        int64 uploadLimitPercent = -_currentUploadLimit;
        // don't use too extreme values
        uploadLimitPercent = qMin (uploadLimitPercent, int64 (90));
        uploadLimitPercent = qMax (int64 (10), uploadLimitPercent);
        int64 wholeTimeMsec = (100.0 / uploadLimitPercent) * relativeLimitMeasuringTimerIntervalMsec;
        int64 waitTimeMsec = wholeTimeMsec - relativeLimitMeasuringTimerIntervalMsec;
        int64 realWaitTimeMsec = waitTimeMsec + wholeTimeMsec;
        qCDebug (lcBandwidthManager) << waitTimeMsec << " - " << realWaitTimeMsec << " msec for " << uploadLimitPercent << "%";
    
        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any upload to timeout
        _relativeUploadDelayTimer.setInterval (realWaitTimeMsec);
        _relativeUploadDelayTimer.start ();
    
        auto deviceCount = _relativeUploadDeviceList.size ();
        int64 quotaPerDevice = relativeLimitProgressDifference * (uploadLimitPercent / 100.0) / deviceCount + 1.0;
        Q_FOREACH (UploadDevice *ud, _relativeUploadDeviceList) {
            ud.setBandwidthLimited (true);
            ud.setChoked (false);
            ud.giveBandwidthQuota (quotaPerDevice);
            qCDebug (lcBandwidthManager) << "Gave" << quotaPerDevice / 1024.0 << "kB to" << ud;
        }
        _relativeLimitCurrentMeasuredDevice = nullptr;
    }
    
    void BandwidthManager.relativeUploadDelayTimerExpired () {
        // Switch to measuring state
        _relativeUploadMeasuringTimer.start (); // always start to continue the cycle
    
        if (!usingRelativeUploadLimit ()) {
            return; // oh, not actually needed
        }
    
        if (_relativeUploadDeviceList.empty ()) {
            return;
        }
    
        qCDebug (lcBandwidthManager) << _relativeUploadDeviceList.size () << "Starting measuring";
    
        // Take first device and then append it again (= we round robin all devices)
        _relativeLimitCurrentMeasuredDevice = _relativeUploadDeviceList.front ();
        _relativeUploadDeviceList.pop_front ();
        _relativeUploadDeviceList.push_back (_relativeLimitCurrentMeasuredDevice);
    
        _relativeUploadLimitProgressAtMeasuringRestart = (_relativeLimitCurrentMeasuredDevice._readWithProgress
                                                             + _relativeLimitCurrentMeasuredDevice._read)
            / 2;
        _relativeLimitCurrentMeasuredDevice.setBandwidthLimited (false);
        _relativeLimitCurrentMeasuredDevice.setChoked (false);
    
        // choke all other UploadDevices
        Q_FOREACH (UploadDevice *ud, _relativeUploadDeviceList) {
            if (ud != _relativeLimitCurrentMeasuredDevice) {
                ud.setBandwidthLimited (true);
                ud.setChoked (true);
            }
        }
    
        // now we're in measuring state
    }
    
    // for downloads:
    void BandwidthManager.relativeDownloadMeasuringTimerExpired () {
        if (!usingRelativeDownloadLimit () || _downloadJobList.empty ()) {
            // Not in this limiting mode, just wait 1 sec to continue the cycle
            _relativeDownloadDelayTimer.setInterval (1000);
            _relativeDownloadDelayTimer.start ();
            return;
        }
        if (!_relativeLimitCurrentMeasuredJob) {
            qCDebug (lcBandwidthManager) << "No job set, just waiting 1 sec";
            _relativeDownloadDelayTimer.setInterval (1000);
            _relativeDownloadDelayTimer.start ();
            return;
        }
    
        qCDebug (lcBandwidthManager) << _downloadJobList.size () << "Starting Delay";
    
        int64 relativeLimitProgressMeasured = _relativeLimitCurrentMeasuredJob.currentDownloadPosition ();
        int64 relativeLimitProgressDifference = relativeLimitProgressMeasured - _relativeDownloadLimitProgressAtMeasuringRestart;
        qCDebug (lcBandwidthManager) << _relativeDownloadLimitProgressAtMeasuringRestart
                                    << relativeLimitProgressMeasured << relativeLimitProgressDifference;
    
        int64 speedkBPerSec = (relativeLimitProgressDifference / relativeLimitMeasuringTimerIntervalMsec * 1000) / 1024;
        qCDebug (lcBandwidthManager) << relativeLimitProgressDifference / 1024 << "kB =>" << speedkBPerSec << "kB/sec on full speed ("
                                    << _relativeLimitCurrentMeasuredJob.currentDownloadPosition ();
    
        int64 downloadLimitPercent = -_currentDownloadLimit;
        // don't use too extreme values
        downloadLimitPercent = qMin (downloadLimitPercent, int64 (90));
        downloadLimitPercent = qMax (int64 (10), downloadLimitPercent);
        int64 wholeTimeMsec = (100.0 / downloadLimitPercent) * relativeLimitMeasuringTimerIntervalMsec;
        int64 waitTimeMsec = wholeTimeMsec - relativeLimitMeasuringTimerIntervalMsec;
        int64 realWaitTimeMsec = waitTimeMsec + wholeTimeMsec;
        qCDebug (lcBandwidthManager) << waitTimeMsec << " - " << realWaitTimeMsec << " msec for " << downloadLimitPercent << "%";
    
        // We want to wait twice as long since we want to give all
        // devices the same quota we used now since we don't want
        // any download to timeout
        _relativeDownloadDelayTimer.setInterval (realWaitTimeMsec);
        _relativeDownloadDelayTimer.start ();
    
        auto jobCount = _downloadJobList.size ();
        int64 quota = relativeLimitProgressDifference * (downloadLimitPercent / 100.0);
        if (quota > 20 * 1024) {
            qCInfo (lcBandwidthManager) << "ADJUSTING QUOTA FROM " << quota << " TO " << quota - 20 * 1024;
            quota -= 20 * 1024;
        }
        int64 quotaPerJob = quota / jobCount + 1;
        Q_FOREACH (GETFileJob *gfj, _downloadJobList) {
            gfj.setBandwidthLimited (true);
            gfj.setChoked (false);
            gfj.giveBandwidthQuota (quotaPerJob);
            qCDebug (lcBandwidthManager) << "Gave" << quotaPerJob / 1024.0 << "kB to" << gfj;
        }
        _relativeLimitCurrentMeasuredDevice = nullptr;
    }
    
    void BandwidthManager.relativeDownloadDelayTimerExpired () {
        // Switch to measuring state
        _relativeDownloadMeasuringTimer.start (); // always start to continue the cycle
    
        if (!usingRelativeDownloadLimit ()) {
            return; // oh, not actually needed
        }
    
        if (_downloadJobList.empty ()) {
            qCDebug (lcBandwidthManager) << _downloadJobList.size () << "No jobs?";
            return;
        }
    
        qCDebug (lcBandwidthManager) << _downloadJobList.size () << "Starting measuring";
    
        // Take first device and then append it again (= we round robin all devices)
        _relativeLimitCurrentMeasuredJob = _downloadJobList.front ();
        _downloadJobList.pop_front ();
        _downloadJobList.push_back (_relativeLimitCurrentMeasuredJob);
    
        _relativeDownloadLimitProgressAtMeasuringRestart = _relativeLimitCurrentMeasuredJob.currentDownloadPosition ();
        _relativeLimitCurrentMeasuredJob.setBandwidthLimited (false);
        _relativeLimitCurrentMeasuredJob.setChoked (false);
    
        // choke all other download jobs
        Q_FOREACH (GETFileJob *gfj, _downloadJobList) {
            if (gfj != _relativeLimitCurrentMeasuredJob) {
                gfj.setBandwidthLimited (true);
                gfj.setChoked (true);
            }
        }
    
        // now we're in measuring state
    }
    
    // end downloads
    
    void BandwidthManager.switchingTimerExpired () {
        int64 newUploadLimit = _propagator._uploadLimit;
        if (newUploadLimit != _currentUploadLimit) {
            qCInfo (lcBandwidthManager) << "Upload Bandwidth limit changed" << _currentUploadLimit << newUploadLimit;
            _currentUploadLimit = newUploadLimit;
            Q_FOREACH (UploadDevice *ud, _relativeUploadDeviceList) {
                if (newUploadLimit == 0) {
                    ud.setBandwidthLimited (false);
                    ud.setChoked (false);
                } else if (newUploadLimit > 0) {
                    ud.setBandwidthLimited (true);
                    ud.setChoked (false);
                } else if (newUploadLimit < 0) {
                    ud.setBandwidthLimited (true);
                    ud.setChoked (true);
                }
            }
        }
        int64 newDownloadLimit = _propagator._downloadLimit;
        if (newDownloadLimit != _currentDownloadLimit) {
            qCInfo (lcBandwidthManager) << "Download Bandwidth limit changed" << _currentDownloadLimit << newDownloadLimit;
            _currentDownloadLimit = newDownloadLimit;
            Q_FOREACH (GETFileJob *j, _downloadJobList) {
                if (usingAbsoluteDownloadLimit ()) {
                    j.setBandwidthLimited (true);
                    j.setChoked (false);
                } else if (usingRelativeDownloadLimit ()) {
                    j.setBandwidthLimited (true);
                    j.setChoked (true);
                } else {
                    j.setBandwidthLimited (false);
                    j.setChoked (false);
                }
            }
        }
    }
    
    void BandwidthManager.absoluteLimitTimerExpired () {
        if (usingAbsoluteUploadLimit () && !_absoluteUploadDeviceList.empty ()) {
            int64 quotaPerDevice = _currentUploadLimit / qMax ( (std.list<UploadDevice>.size_type)1, _absoluteUploadDeviceList.size ());
            qCDebug (lcBandwidthManager) << quotaPerDevice << _absoluteUploadDeviceList.size () << _currentUploadLimit;
            Q_FOREACH (UploadDevice *device, _absoluteUploadDeviceList) {
                device.giveBandwidthQuota (quotaPerDevice);
                qCDebug (lcBandwidthManager) << "Gave " << quotaPerDevice / 1024.0 << " kB to" << device;
            }
        }
        if (usingAbsoluteDownloadLimit () && !_downloadJobList.empty ()) {
            int64 quotaPerJob = _currentDownloadLimit / qMax ( (std.list<GETFileJob>.size_type)1, _downloadJobList.size ());
            qCDebug (lcBandwidthManager) << quotaPerJob << _downloadJobList.size () << _currentDownloadLimit;
            Q_FOREACH (GETFileJob *j, _downloadJobList) {
                j.giveBandwidthQuota (quotaPerJob);
                qCDebug (lcBandwidthManager) << "Gave " << quotaPerJob / 1024.0 << " kB to" << j;
            }
        }
    }
    
    } // namespace Occ
    