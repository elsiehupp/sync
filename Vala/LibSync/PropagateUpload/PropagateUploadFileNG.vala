/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
//  Q_DECLARE_LOGGING_CATEGORY (lc_propagate_upload_nG)
/***********************************************************
@ingroup libsync

Propagation job, impementing the new chunking agorithm

***********************************************************/
class PropagateUploadFileNG : PropagateUploadFileCommon {

    /***********************************************************
    ***********************************************************/
    private int64 this.sent = 0; /// amount of data (bytes) that was already sent
    private uint32 this.transfer_id = 0; /// transfer identifier (part of the url)
    private int this.current_chunk = 0; /// Id of the next chunk that will be sent
    private int64 this.current_chunk_size = 0; /// current chunk size
    private bool this.remove_job_error = false; /// If not null, there was an error removing the job

    // Map chunk number with its size  from the PROPFIND on resume.
    // (Only used from on_propfind_iterate/on_propfind_finished because the LsColJob use signals to report data.)
    private struct Server_chunk_info {
        int64 size;
        string original_name;
    };
    private GLib.HashMap<int64, Server_chunk_info> this.server_chunks;


    /***********************************************************
    Return the URL of a chunk.
    If chunk == -1, returns the URL of the parent folder containing the chunks
    ***********************************************************/
    private GLib.Uri chunk_url (int chunk = -1);


    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileNG (OwncloudPropagator propagator, SyncFileItemPtr item)
        : PropagateUploadFileCommon (propagator, item) {
    }


    /***********************************************************
    ***********************************************************/
    public void do_start_upload () override;


    /***********************************************************
    ***********************************************************/
    private void start_new_upload ();
    private void on_start_next_chunk ();

    /***********************************************************
    ***********************************************************/
    public void on_abort (AbortType abort_type) override;

    /***********************************************************
    ***********************************************************/
    private void on_propfind_finished ();
    private void on_propfind_finished_with_error ();
    private void on_propfind_iterate (string name, GLib.HashMap<string, string> properties);
    private void on_delete_job_finished ();
    private void on_mk_col_finished ();
    private void on_put_finished ();
    private void on_move_job_finished ();
    private void on_upload_progress (int64, int64);
};