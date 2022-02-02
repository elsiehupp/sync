/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
/***********************************************************
@brief The UploadDevice class
@ingroup libsync
***********************************************************/
class UploadDevice : QIODevice {

    /***********************************************************
    ***********************************************************/
    public UploadDevice (string filename, int64 on_start, int64 size, BandwidthManager bwm);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void close () override;

    public int64 write_data (char *, int64) override;
    public int64 read_data (char data, int64 maxlen) override;
    public bool at_end () override;
    public int64 size () override;
    public int64 bytes_available () override;
    public bool is_sequential () override;
    public bool seek (int64 pos) override;

    /***********************************************************
    ***********************************************************/
    public void set_bandwidth_limited (bool);

    /***********************************************************
    ***********************************************************/
    public 
    public bool is_bandwidth_limited () {
        return this.bandwidth_limited;
    }


    /***********************************************************
    ***********************************************************/
    public void set_choked (bool);

    /***********************************************************
    ***********************************************************/
    public 
    public bool is_choked () {
        return this.choked;
    }


    /***********************************************************
    ***********************************************************/
    public void give_bandwidth_quota (int64 bwq);


    /// The local file to read data from
    private GLib.File this.file;

    /// Start of the file data to use
    private int64 this.start = 0;
    /// Amount of file data after this.start to use
    private int64 this.size = 0;
    /// Position between this.start and this.start+this.size
    private int64 this.read = 0;

    // Bandwidth manager related
    private QPointer<BandwidthManager> this.bandwidth_manager;
    private int64 this.bandwidth_quota = 0;
    private int64 this.read_with_progress = 0;
    private bool this.bandwidth_limited = false; // if this.bandwidth_quota will be used
    private bool this.choked = false; // if upload is paused (read_data () will return 0)
    private friend class BandwidthManager;

    /***********************************************************
    ***********************************************************/
    public void on_job_upload_progress (int64 sent, int64 t);
}




    UploadDevice.UploadDevice (string filename, int64 on_start, int64 size, BandwidthManager bwm)
        : this.file (filename)
        , this.start (on_start)
        , this.size (size)
        , this.bandwidth_manager (bwm) {
        this.bandwidth_manager.on_register_upload_device (this);
    }

    UploadDevice.~UploadDevice () {
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_unregister_upload_device (this);
        }
    }

    bool UploadDevice.open (QIODevice.Open_mode mode) {
        if (mode & QIODevice.WriteOnly)
            return false;

        // Get the file size now : this.file.filename () is no longer reliable
        // on all platforms after open_and_seek_file_shared_read ().
        var file_disk_size = FileSystem.get_size (this.file.filename ());

        string open_error;
        if (!FileSystem.open_and_seek_file_shared_read (&this.file, open_error, this.start)) {
            on_set_error_string (open_error);
            return false;
        }

        this.size = q_bound (0ll, this.size, file_disk_size - this.start);
        this.read = 0;

        return QIODevice.open (mode);
    }

    void UploadDevice.close () {
        this.file.close ();
        QIODevice.close ();
    }

    int64 UploadDevice.write_data (char *, int64) {
        ASSERT (false, "write to read only device");
        return 0;
    }

    int64 UploadDevice.read_data (char data, int64 maxlen) {
        if (this.size - this.read <= 0) {
            // at end
            if (this.bandwidth_manager) {
                this.bandwidth_manager.on_unregister_upload_device (this);
            }
            return -1;
        }
        maxlen = q_min (maxlen, this.size - this.read);
        if (maxlen <= 0) {
            return 0;
        }
        if (is_choked ()) {
            return 0;
        }
        if (is_bandwidth_limited ()) {
            maxlen = q_min (maxlen, this.bandwidth_quota);
            if (maxlen <= 0) { // no quota
                return 0;
            }
            this.bandwidth_quota -= maxlen;
        }

        var c = this.file.read (data, maxlen);
        if (c < 0) {
            on_set_error_string (this.file.error_string ());
            return -1;
        }
        this.read += c;
        return c;
    }

    void UploadDevice.on_job_upload_progress (int64 sent, int64 t) {
        if (sent == 0 || t == 0) {
            return;
        }
        this.read_with_progress = sent;
    }

    bool UploadDevice.at_end () {
        return this.read >= this.size;
    }

    int64 UploadDevice.size () {
        return this.size;
    }

    int64 UploadDevice.bytes_available () {
        return this.size - this.read + QIODevice.bytes_available ();
    }

    // random access, we can seek
    bool UploadDevice.is_sequential () {
        return false;
    }

    bool UploadDevice.seek (int64 pos) {
        if (!QIODevice.seek (pos)) {
            return false;
        }
        if (pos < 0 || pos > this.size) {
            return false;
        }
        this.read = pos;
        this.file.seek (this.start + pos);
        return true;
    }

    void UploadDevice.give_bandwidth_quota (int64 bwq) {
        if (!at_end ()) {
            this.bandwidth_quota = bwq;
            QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection); // tell QNAM that we have quota
        }
    }

    void UploadDevice.set_bandwidth_limited (bool b) {
        this.bandwidth_limited = b;
        QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection);
    }

    void UploadDevice.set_choked (bool b) {
        this.choked = b;
        if (!this.choked) {
            QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection);
        }
    }