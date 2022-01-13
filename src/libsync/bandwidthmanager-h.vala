/*
Copyright (C) by Markus Goetz <markus@woboq.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QTimer>
// #include <QIODevice>
// #include <list>

namespace Occ {

class GETFileJob;

/**
@brief The BandwidthManager class
@ingroup libsync
*/
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
