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
    The local file to read data from
    ***********************************************************/
    private GLib.File file;


    /***********************************************************
    Start of the file data to use
    ***********************************************************/
    private int64 start = 0;


    /***********************************************************
    Amount of file data after this.start to use
    ***********************************************************/
    private int64 size = 0;


    /***********************************************************
    Position between this.start and this.start+this.size
    ***********************************************************/
    private int64 read = 0;


    /***********************************************************
    Bandwidth manager related
    ***********************************************************/
    private QPointer<BandwidthManager> bandwidth_manager;


    /***********************************************************
    Bandwidth manager related
    ***********************************************************/
    private int64 bandwidth_quota = 0;


    /***********************************************************
    Bandwidth manager related
    ***********************************************************/
    private int64 read_with_progress = 0;


    /***********************************************************
    Bandwidth manager related
    If this.bandwidth_quota will be used
    ***********************************************************/
    private bool bandwidth_limited = false;


    /***********************************************************
    Bandwidth manager related
    If upload is paused (read_data () will return 0)
    ***********************************************************/
    private bool choked = false; 

    private friend class BandwidthManager;

    /***********************************************************
    ***********************************************************/
    public UploadDevice (string filename, int64 start, int64 size, BandwidthManager bandwidth_manager) {
        this.file = filename;
        this.start = start;
        this.size = size;
        this.bandwidth_manager = bandwidth_manager;
        this.bandwidth_manager.on_register_upload_device (this);
    }


    ~UploadDevice () {
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_unregister_upload_device (this);
        }
    }



    /***********************************************************
    ***********************************************************/
    public 
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


    /***********************************************************
    ***********************************************************/
    public void close () override;
    void UploadDevice.close () {
        this.file.close ();
        QIODevice.close ();
    }


    /***********************************************************
    ***********************************************************/
    public int64 write_data (string unused_string, int64 unused_int64) {
        //  ASSERT (false, "write to read only device");
        return 0;
    }


    /***********************************************************
    ***********************************************************/
    public int64 read_data (char data, int64 maxlen) {
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


    /***********************************************************
    ***********************************************************/
    public bool at_end () override;
    bool UploadDevice.at_end () {
        return this.read >= this.size;
    }


    /***********************************************************
    ***********************************************************/
    public int64 size () override;
    int64 UploadDevice.size () {
        return this.size;
    }


    /***********************************************************
    ***********************************************************/
    public int64 bytes_available () override;
    int64 UploadDevice.bytes_available () {
        return this.size - this.read + QIODevice.bytes_available ();
    }


    /***********************************************************
    Random access, we can seek
    ***********************************************************/
    public bool is_sequential () {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public bool seek (int64 position) {
        if (!QIODevice.seek (position)) {
            return false;
        }
        if (position < 0 || position > this.size) {
            return false;
        }
        this.read = position;
        this.file.seek (this.start + position);
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void set_bandwidth_limited (bool);


    /***********************************************************
    ***********************************************************/
    public bool is_bandwidth_limited () {
        return this.bandwidth_limited;
    }


    /***********************************************************
    ***********************************************************/
    public void set_choked (bool);


    /***********************************************************
    ***********************************************************/
    public bool is_choked () {
        return this.choked;
    }


    /***********************************************************
    ***********************************************************/
    public void give_bandwidth_quota (int64 bwq);


    /***********************************************************
    ***********************************************************/
    public void on_job_upload_progress (int64 sent, int64 t);
    void UploadDevice.on_job_upload_progress (int64 sent, int64 t) {
        if (sent == 0 || t == 0) {
            return;
        }
        this.read_with_progress = sent;
    }
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