/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@ingroup libsync

Propagation job, impementing the old chunking agorithm

***********************************************************/
class PropagateUploadFileV1 : PropagateUploadFileCommon {


    /***********************************************************
    That's the on_signal_start chunk that was stored in the database for resuming.
    In the non-resuming case it is 0.
    If we are resuming, this is the first chunk we need to send
    ***********************************************************/
    private int this.start_chunk = 0;
    /***********************************************************
    This is the next chunk that we need to send. Starting from 0 even if this.start_chunk != 0
    (In other words,  this.start_chunk + this.current_chunk is really the number of the chunk we need to send next)
    (In other words, this.current_chunk is the number of the chunk that we already sent or started sending)
    ***********************************************************/
    private int this.current_chunk = 0;
    private int this.chunk_count = 0; /// Total number of chunks for this file
    private uint32 this.transfer_id = 0; /// transfer identifier (part of the url)

    /***********************************************************
    ***********************************************************/
    private int64 chunk_size () {
        // Old chunking does not use dynamic chunking algorithm, and does not adjusts the chunk size respectively,
        // thus this value should be used as the one classifing item to be chunked
        return propagator ().sync_options ().initial_chunk_size;
    }


    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileV1 (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateUploadFileCommon (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void do_start_upload () override;

    /***********************************************************
    ***********************************************************/
    public void on_signal_abort (PropagatorJob.AbortType abort_type) override;

    /***********************************************************
    ***********************************************************/
    private void on_signal_start_next_chunk ();
    private void on_signal_put_finished ();
    private void on_signal_upload_progress (int64, int64);
};