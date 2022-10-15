namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateUploadFileNG

@brief Propagation job, impementing the new chunking agorithm

State machine:

    *---. do_start_upload ()
        //      Check the database : is there an entry?
        //      /
        //      no                yes
        //      /
        //  /                  PROPFIND
    start_new_upload () <-+        +----------------------------
        //  |               |        |
        //  MKCOL            + on_signal_lscol_job_finished_with_error ()     on_signal_lscol_job_finished ()
        //  |                                                       Is there stale files to remove?
    on_signal_mkcol_job_finished ()                                         |                      |
        //  |                                                       no                    yes
        //  |                                                       |                      |
        //  |                                                       |                  KeychainChunkDeleteJob
        //  |                                                       |                      |
    +-----+<------------------------------------------------------+<---  on_signal_delete_job_finished ()
    |
    +---.  on_signal_start_next_chunk ()  ---on_signal_finished?  --+
        //          ^               |          |
        //          +---------------+          |
        //                                      |
    +----------------------------------------+
    |
    +. MOVE -----. move_job_finished () --. on_signal_finalize ()


@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateUploadFileNG : PropagateUploadFileCommon {

    /***********************************************************
    Map chunk number with its size  from the PROPFIND on resume.
    (Only used from on_signal_lscol_job_directory_listing_iterated or
    on_signal_lscol_job_finished because the LscolJob use
    signals to report data.)
    ***********************************************************/
    private class ServerChunkInfo {
        //  int64 size;
        //  string original_name;
    }

    /***********************************************************
    Amount of data (bytes) that was already sent
    ***********************************************************/
    private int64 sent = 0;

    /***********************************************************
    Transfer identifier (part of the url)
    ***********************************************************/
    private uint32 transfer_identifier = 0;

    /***********************************************************
    Identifier of the next chunk that will be sent
    ***********************************************************/
    private int current_chunk = 0;

    /***********************************************************
    Current chunk size
    ***********************************************************/
    private int64 current_chunk_size = 0;

    /***********************************************************
    If not null, there was an error removing the job
    ***********************************************************/
    private bool remove_job_error = false;

    private GLib.HashTable<int64?, ServerChunkInfo?> server_chunks;


    /***********************************************************
    Return the URL of a chunk.
    If chunk == -1, returns the URL of the parent folder containing the chunks
    ***********************************************************/
    private GLib.Uri chunk_url (int chunk = -1) {
        //  string path = "remote.php/dav/uploads/"
        //      + this.propagator.account.dav_user
        //      + "/" + this.transfer_identifier.to_string ();
        //  if (chunk >= 0) {
        //      // We need to do add leading 0 because the server orders the chunk alphabetically
        //      path += "/" + string.number (chunk).right_justified (16, '0'); // 1e16 is 10 petabyte
        //  }
        //  return Utility.concat_url_path (this.propagator.account.url, path);
    }


    /***********************************************************
    ***********************************************************/
    public PropagateUploadFileNG (OwncloudPropagator propagator, SyncFileItem item) {
        //  base (propagator, item);
    }


    /***********************************************************
    ***********************************************************/
    public new void do_start_upload () {
        //  this.propagator.active_job_list.append (this);

        //  Common.SyncJournalDb.UploadInfo progress_info = this.propagator.journal.get_upload_info (this.item.file);
        //  GLib.assert (this.item.modtime > 0);
        //  if (this.item.modtime <= 0) {
        //      GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        //  }
        //  if (progress_info.valid && progress_info.is_chunked && progress_info.modtime == this.item.modtime
        //          && progress_info.size == this.item.size) {
        //      this.transfer_identifier = progress_info.transferid;
        //      var url = chunk_url ();
        //      var lscol_job = new LscolJob (this.propagator.account, url, this);
        //      this.jobs.append (lscol_job);
        //      lscol_job.properties = {
        //          "resourcetype",
        //          "getcontentlength"
        //      };
        //      lscol_job.signal_finished_without_error.connect (
        //          this.on_signal_lscol_job_finished
        //      );
        //      lscol_job.signal_finished_with_error.connect (
        //          this,
        //          PropagateUploadFileNG.on_signal_lscol_job_finished_with_error
        //      );
        //      lscol_job.destroyed.connect (
        //          this.on_signal_network_job_destroyed
        //      );
        //      lscol_job.signal_directory_listing_iterated.connect (
        //          this.on_signal_lscol_job_directory_listing_iterated
        //      );
        //      lscol_job.start ();
        //      return;
        //  } else if (progress_info.valid && progress_info.is_chunked) {
        //      // The upload info is stale. remove the stale chunks on the server
        //      this.transfer_identifier = progress_info.transferid;
        //      // Fire and forget. Any error will be ignored.
        //      (new KeychainChunkDeleteJob (this.propagator.account, chunk_url (), this)).start ();
        //      // start_new_upload will reset the this.transfer_identifier and the UploadInfo in the database.
        //  }

        //  start_new_upload ();
    }


    /***********************************************************
    ***********************************************************/
    private void start_new_upload () {
        //  //  GLib.assert_true (this.propagator.active_job_list.count (this) == 1);
        //  GLib.assert (this.item.modtime > 0);
        //  if (this.item.modtime <= 0) {
        //      GLib.warning ("Invalid modified time" + this.item.file.to_string () + this.item.modtime.to_string ());
        //  }
        //  this.transfer_identifier = ((uint32)Utility.rand ()) ^ ((uint32)this.item.modtime) ^ ((uint32)this.file_to_upload.size << 16) ^ q_hash (this.file_to_upload.file));
        //  this.sent = 0;
        //  this.current_chunk = 0;

        //  this.propagator.report_progress (this.item, 0);

        //  Common.SyncJournalDb.UploadInfo pi;
        //  pi.valid = true;
        //  pi.transferid = this.transfer_identifier;
        //  GLib.assert (this.item.modtime > 0);
        //  if (this.item.modtime <= 0) {
        //      GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        //  }
        //  pi.modtime = this.item.modtime;
        //  pi.content_checksum = this.item.checksum_header;
        //  pi.size = this.item.size;
        //  this.propagator.journal.upload_info (this.item.file, pi);
        //  this.propagator.journal.commit ("Upload info");
        //  GLib.HashTable<string, string> headers;

        //  // But we should send the temporary (or something) one.
        //  headers["OC-Total-Length"] = new string.number (this.file_to_upload.size);
        //  var mkcol_job = new MkColJob (this.propagator.account, chunk_url (), headers, this);

        //  mkcol_job.signal_finished_with_error.connect (
        //      this.on_signal_mkcol_job_finished
        //  );
        //  mkcol_job.signal_finished_without_error.connect (
        //      this.on_signal_mkcol_job_finished
        //  );
        //  mkcol_job.destroyed.connect (
        //      this.on_signal_network_job_destroyed
        //  );
        //  mkcol_job.start ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_start_next_chunk () {
        //  if (this.propagator.abort_requested) {
        //      return;
        //  }

        //  int64 file_size = this.file_to_upload.size;
        //  //  ENFORCE (file_size >= this.sent, "Sent data exceeds file size");

        //  // prevent situation that chunk size is bigger then required one to send
        //  this.current_chunk_size = int64.min (this.propagator.chunk_size, file_size - this.sent);

        //  if (this.current_chunk_size == 0) {
        //      GLib.assert (this.jobs.length () == 0); // There should be no running job anymore
        //      this.finished = true;

        //      // Finish with a MOVE
        //      // If we changed the file name, we must store the changed filename in the remote folder, not the original one.
        //      string destination = GLib.Dir.clean_path (this.propagator.account.dav_url ().path
        //          + this.propagator.full_remote_path (this.file_to_upload.file));
        //      var headers = PropagateUploadFileCommon.headers ();

        //      // "If-Match applies to the source, but we are interested in comparing the etag of the destination
        //      var if_match = headers.take ("If-Match");
        //      if (!if_match == "") {
        //          headers["If"] = "<" + GLib.Uri.to_percent_encoding (destination, "/") + "> ([" + if_match + "])";
        //      }
        //      if (this.transmission_checksum_header != "") {
        //          GLib.info (destination + this.transmission_checksum_header);
        //          headers[CHECK_SUM_HEADER_C] = this.transmission_checksum_header;
        //      }
        //      headers["OC-Total-Length"] = new string.number (file_size);

        //      var move_job = new MoveJob (this.propagator.account, Utility.concat_url_path (chunk_url (), "/.file"),
        //          destination, headers, this);
        //      this.jobs.append (move_job);
        //      move_job.signal_move_job_finished.connect (
        //          this.on_signal_move_job_finished
        //      );
        //      move_job.destroyed.connect (
        //          this.on_signal_network_job_destroyed
        //      );
        //      this.propagator.active_job_list.append (this);
        //      adjust_last_job_timeout (move_job, file_size);
        //      move_job.start ();
        //      return;
        //  }

        //  var device = std.make_unique<UploadDevice> (
        //          this.file_to_upload.path, this.sent, this.current_chunk_size, this.propagator.bandwidth_manager);
        //  if (!device.open (GLib.IODevice.ReadOnly)) {
        //      GLib.warning ("Could not prepare upload device: " + device.error_string);

        //      // Soft error because this is likely caused by the user modifying his files while syncing
        //      abort_with_error (SyncFileItem.Status.SOFT_ERROR, device.error_string);
        //      return;
        //  }

        //  GLib.HashTable<string, string> headers;
        //  headers["OC-Chunk-Offset"] = new string.number (this.sent);

        //  this.sent += this.current_chunk_size;
        //  GLib.Uri url = chunk_url (this.current_chunk);

        //  // job takes ownership of device via a GLib.ScopedPointer. Job deletes itself when finishing
        //  var device_ptr = device; // for connections later
        //  var put_file_job = new PUTFileJob (this.propagator.account, url, std.move (device), headers, this.current_chunk, this);
        //  this.jobs.append (put_file_job);
        //  put_file_job.signal_finished.connect (
        //      this.on_signal_put_file_job_finished
        //  );
        //  put_file_job.signal_upload_progress.connect (
        //      this.on_signal_put_file_job_upload_progress
        //  );
        //  put_file_job.signal_upload_progress.connect (
        //      device_ptr.on_signal_put_file_job_upload_progress
        //  );
        //  put_file_job.destroyed.connect (
        //      this.on_signal_network_job_destroyed
        //  );
        //  put_file_job.start ();
        //  this.propagator.active_job_list.append (this);
        //  this.current_chunk++;
    }

    /***********************************************************
    ***********************************************************/
    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
        //  abort_network_jobs (
        //      abort_type,
        //      PropagateUploadNg.abort_filter
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private static bool abort_filter (AbstractPropagatorJob.AbortType abort_type, AbstractNetworkJob abstract_job) {
        //  return abort_type != AbstractPropagatorJob.AbortType.ASYNCHRONOUS || (MoveJob)abstract_job == null;
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_job_finished () {
        //  var lscol_job = (LscolJob)sender ();
        //  on_signal_network_job_destroyed (lscol_job); // remove it from the this.jobs list
        //  this.propagator.active_job_list.remove_one (this);

        //  this.current_chunk = 0;
        //  this.sent = 0;
        //  while (this.server_chunks.contains (this.current_chunk)) {
        //      this.sent += this.server_chunks[this.current_chunk].size;
        //      this.server_chunks.remove (this.current_chunk);
        //      ++this.current_chunk;
        //  }

        //  if (this.sent > this.file_to_upload.size) {
        //      // Normally this can't happen because the size is xor'ed with the transfer identifier, and it is
        //      // therefore impossible that there is more data on the server than on the file.
        //      GLib.critical (
        //          "Inconsistency while resuming " + this.item.file.to_string ()
        //          + " : the size on the server (" + this.sent.to_string () + ") is bigger than the size of the file ("
        //          + this.file_to_upload.size.to_string () + ")"
        //      );

        //      // Wipe the old chunking data.
        //      // Fire and forget. Any error will be ignored.
        //      new KeychainChunkDeleteJob (this.propagator.account, chunk_url (), this).start ();

        //      this.propagator.active_job_list.append (this);
        //      start_new_upload ();
        //      return;
        //  }

        //  GLib.info ("Resuming " + this.item.file.to_string () + " from chunk " + this.current_chunk.to_string () + "; sent =" + this.sent.to_string ());

        //  if (this.server_chunks != "") {
        //      GLib.info ("To Delete " + this.server_chunks.keys ());
        //      this.propagator.active_job_list.append (this);
        //      this.remove_job_error = false;

        //      // Make sure that if there is a "hole" and then a few more chunks, on the server
        //      // we should remove the later chunks. Otherwise when we do dynamic chunk sizing, we may end up
        //      // with corruptions if there are too many chunks, or if we abort and there are still stale chunks.
        //      foreach (var server_chunk in q_as_const (this.server_chunks)) {
        //          var delete_job = new KeychainChunkDeleteJob (this.propagator.account, Utility.concat_url_path (chunk_url (), server_chunk.original_name), this);
        //          delete_job.signal_finished.connect (
        //              this.on_signal_delete_job_finished
        //          );
        //          this.jobs.append (delete_job);
        //          delete_job.start ();
        //      }
        //      this.server_chunks = null;
        //      return;
        //  }

        //  on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_job_finished_with_error () {
        //  var lscol_job = (LscolJob)sender ();
        //  on_signal_network_job_destroyed (lscol_job); // remove it from the this.jobs list
        //  GLib.InputStream.NetworkError err = lscol_job.input_stream.error;
        //  var http_error_code = lscol_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  var status = classify_error (err, http_error_code, this.propagator.another_sync_needed);
        //  if (status == SyncFileItem.Status.FATAL_ERROR) {
        //      this.item.request_id = lscol_job.request_id ();
        //      this.propagator.active_job_list.remove_one (this);
        //      abort_with_error (status, lscol_job.error_string_parsing_body ());
        //      return;
        //  }
        //  start_new_upload ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_lscol_job_directory_listing_iterated (string name, GLib.HashTable<string, string> properties) {
        //  if (name == chunk_url ().path) {
        //      return; // skip the info about the path itself
        //  }
        //  bool ok = false;
        //  string chunk_name = name.mid (name.last_index_of ("/") + 1);
        //  var chunk_id = chunk_name.to_long_long (ok);
        //  if (ok) {
        //      this.server_chunks[chunk_id] = ServerChunkInfo (
        //          properties["getcontentlength"].to_long_long (),
        //          chunk_name
        //      );
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_job_finished () {
        //  var delete_job = (KeychainChunkDeleteJob)sender ();
        //  //  GLib.assert_true (delete_job);
        //  this.jobs.remove (this.jobs.index_of (delete_job));

        //  GLib.InputStream.NetworkError err = delete_job.input_stream.error;
        //  if (err != GLib.InputStream.NoError && err != GLib.InputStream.ContentNotFoundError) {
        //      int http_status = delete_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //      SyncFileItem.Status status = classify_error (err, http_status);
        //      if (status == SyncFileItem.Status.FATAL_ERROR) {
        //          this.item.request_id = delete_job.request_id ();
        //          abort_with_error (status, delete_job.error_string);
        //          return;
        //      } else {
        //          GLib.warning ("KeychainChunkDeleteJob errored out " + delete_job.error_string + delete_job.input_stream.url);
        //          this.remove_job_error = true;
        //          // Let the other jobs finish
        //      }
        //  }

        //  if (this.jobs.length () == 0) {
        //      this.propagator.active_job_list.remove_one (this);
        //      if (this.remove_job_error) {
        //          // There was an error removing some files, just start over
        //          start_new_upload ();
        //      } else {
        //          on_signal_start_next_chunk ();
        //      }
        //  }
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_mkcol_job_finished () {
        //  this.propagator.active_job_list.remove_one (this);
        //  var mkcol_job = (MkColJob)sender ();
        //  on_signal_network_job_destroyed (mkcol_job); // remove it from the this.jobs list
        //  GLib.InputStream.NetworkError err = mkcol_job.input_stream.error;
        //  this.item.http_error_code = mkcol_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        //  if (err != GLib.InputStream.NoError || this.item.http_error_code != 201) {
        //      this.item.request_id = mkcol_job.request_id ();
        //      SyncFileItem.Status status = classify_error (err, this.item.http_error_code,
        //          this.propagator.another_sync_needed);
        //      abort_with_error (status, mkcol_job.error_string_parsing_body ());
        //      return;
        //  }
        //  on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_put_file_job_finished () {
        //  var put_file_job = (PUTFileJob)sender ();
        //  //  GLib.assert_true (put_file_job);

        //  on_signal_network_job_destroyed (put_file_job); // remove it from the this.jobs list

        //  this.propagator.active_job_list.remove_one (this);

        //  if (this.finished) {
        //      // We have sent the on_signal_finished signal already. We don't need to handle any remaining jobs
        //      return;
        //  }

        //  GLib.InputStream.NetworkError err = put_file_job.input_stream.error;

        //  if (err != GLib.InputStream.NoError) {
        //      this.item.http_error_code = put_file_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //      this.item.request_id = put_file_job.request_id ();
        //      common_error_handling (put_file_job);
        //      return;
        //  }

        //  //  ENFORCE (this.sent <= this.file_to_upload.size, "can't send more than size");

        //  // Adjust the chunk size for the time taken.
        //  //  
        //  // Dynamic chunk sizing is enabled if the server configured a
        //  // target duration for each chunk upload.
        //  var target_duration = this.propagator.sync_options.target_chunk_upload_duration;
        //  if (target_duration.length > 0) {
        //      var upload_time = ++put_file_job.microseconds_since_start; // add one to avoid div-by-zero
        //      int64 predicted_good_size = (this.current_chunk_size * target_duration) / upload_time;

        //      // The whole targeting is heuristic. The predicted_good_size will fluctuate
        //      // quite a bit because of external factors (like available bandwidth)
        //      // and internal factors (like number of parallel uploads).
        //      //  
        //      // We use an exponential moving average here as a cheap way of smoothing
        //      // the chunk sizes a bit.
        //      int64 target_size = this.propagator.chunk_size / 2 + predicted_good_size / 2;

        //      // Adjust the dynamic chunk size this.chunk_size used for sizing of the item's chunks to be send
        //      this.propagator.chunk_size = q_bound (
        //          this.propagator.sync_options.min_chunk_size,
        //          target_size,
        //          this.propagator.sync_options.max_chunk_size);

        //      GLib.info (
        //          "Chunked upload of " + this.current_chunk_size.to_string () + " bytes took " + upload_time.length
        //          + "ms, desired is " + target_duration.length + "ms, expected good chunk size is "
        //          + predicted_good_size + " bytes and nudged next chunk size to "
        //          + this.propagator.chunk_size + " bytes."
        //      );
        //  }

        //  this.finished = this.sent == this.item.size;

        //  // Check if the file still exists
        //  string full_file_path = this.propagator.full_local_path (this.item.file);
        //  if (!FileSystem.file_exists (full_file_path)) {
        //      if (!this.finished) {
        //          abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("The local file was removed during sync."));
        //          return;
        //      } else {
        //          this.propagator.another_sync_needed = true;
        //      }
        //  }

        //  // Check whether the file changed since discovery - this acts on the original file.
        //  GLib.assert (this.item.modtime > 0);
        //  if (this.item.modtime <= 0) {
        //      GLib.warning ("Invalid modified time " + this.item.file.to_string () + this.item.modtime.to_string ());
        //  }
        //  if (!FileSystem.verify_file_unchanged (full_file_path, this.item.size, this.item.modtime)) {
        //      this.propagator.another_sync_needed = true;
        //      if (!this.finished) {
        //          abort_with_error (SyncFileItem.Status.SOFT_ERROR, _("Local file changed during sync."));
        //          return;
        //      }
        //  }

        //  if (!this.finished) {
        //      // Deletes an existing blocklist entry on successful chunk upload
        //      if (this.item.has_blocklist_entry) {
        //          this.propagator.journal.wipe_error_blocklist_entry (this.item.file);
        //          this.item.has_blocklist_entry = false;
        //      }

        //      // Reset the error count on successful chunk upload
        //      var upload_info = this.propagator.journal.get_upload_info (this.item.file);
        //      upload_info.error_count = 0;
        //      this.propagator.journal.upload_info (this.item.file, upload_info);
        //      this.propagator.journal.commit ("Upload info");
        //  }
        //  on_signal_start_next_chunk ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_move_job_finished (MoveJob move_job) {
        //  this.propagator.active_job_list.remove_one (this);
        //  var move_job = (MoveJob)sender ();
        //  on_signal_network_job_destroyed (move_job); // remove it from the this.jobs list
        //  GLib.InputStream.NetworkError err = move_job.input_stream.error;
        //  this.item.http_error_code = move_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  this.item.response_time_stamp = move_job.response_timestamp;
        //  this.item.request_id = move_job.request_id ();

        //  if (err != GLib.InputStream.NoError) {
        //      common_error_handling (move_job);
        //      return;
        //  }

        //  if (this.item.http_error_code == 202) {
        //      string path = string.from_utf8 (move_job.input_stream.raw_header ("OC-Job_status-Location"));
        //      if (path == "") {
        //          on_signal_done (SyncFileItem.Status.NORMAL_ERROR, _("Poll URL missing"));
        //          return;
        //      }
        //      this.finished = true;
        //      start_poll_job (path);
        //      return;
        //  }

        //  if (this.item.http_error_code != 201 && this.item.http_error_code != 204) {
        //      abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Unexpected return code from server (%1)").printf (this.item.http_error_code));
        //      return;
        //  }

        //  string fid = move_job.input_stream.raw_header ("OC-FileID");
        //  if (fid == "") {
        //      GLib.warning ("Server did not return a OC-FileID " + this.item.file);
        //      abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing File ID from server"));
        //      return;
        //  } else {
        //      // the old file identifier should only be empty for new files uploaded
        //      if (!this.item.file_id == "" && this.item.file_id != fid) {
        //          GLib.warning ("File ID changed! " + this.item.file_id.to_string () + fid);
        //      }
        //      this.item.file_id = fid;
        //  }

        //  this.item.etag = get_etag_from_reply (move_job.input_stream);
        //  ;
        //  if (this.item.etag == "") {
        //      GLib.warning ("Server did not return an ETAG " + this.item.file);
        //      abort_with_error (SyncFileItem.Status.NORMAL_ERROR, _("Missing ETag from server"));
        //      return;
        //  }
        //  on_signal_finalize ();
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_put_file_job_upload_progress (int64 sent, int64 total) {
        //  // Completion is signaled with sent=0, total=0; avoid accidentally
        //  // resetting progress due to the sent being zero by ignoring it.
        //  // signal_finished () is bound to be emitted soon anyway.
        //  // See https://bugreports.qt.io/browse/GLib.TBUG-44782.
        //  if (sent == 0 && total == 0) {
        //      return;
        //  }
        //  this.propagator.report_progress (this.item, this.sent + sent - total);
    }

} // class PropagateUploadFileNG

} // namespace LibSync
} // namespace Occ
