/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class FakeFolder {

    /***********************************************************
    ***********************************************************/
    public struct ErrorList {

        FakeQNAM qnam;

        void append (string path, int error = 500) {
            this.qnam.error_paths ().insert (path, error);
        }

        void clear () {
            this.qnam.error_paths ().clear ();
        }
    }

    QTemporaryDir temporary_directory;
    DiskFileModifier local_modifier;

    // FIXME : Clarify ownership, double delete
    FakeQNAM fake_qnam;
    Occ.AccountPointer account;
    std.unique_ptr<Occ.SyncJournalDb> journal_database;
    std.unique_ptr<Occ.SyncEngine> sync_engine;


    /***********************************************************
    ***********************************************************/
    public FakeFolder (FileInfo template_file_info, Occ.Optional<FileInfo> local_file_info = new Occ.Optional<FileInfo> (), string remote_path = "") {
        this.local_modifier = this.temporary_directory.path ();
        // Needs to be done once
        Occ.SyncEngine.minimumFileAgeForUpload = std.chrono.milliseconds (0);
        Occ.Logger.instance ().setLogFile (QStringLiteral ("-"));
        Occ.Logger.instance ().addLogRule ({ QStringLiteral ("sync.httplogger=true") });
    
        QDir root_directory = new QDir (this.temporary_directory.path ());
        GLib.debug ("FakeFolder operating on " + root_directory);
        if (local_file_info) {
            to_disk (root_directory, *local_file_info);
        } else {
            to_disk (root_directory, template_file_info);
        }
    
        this.fake_qnam = new FakeQNAM (template_file_info);
        this.account = Occ.Account.create ();
        this.account.set_url (GLib.Uri ("http://admin:admin@localhost/owncloud"));
        this.account.setCredentials (new FakeCredentials (this.fake_qnam));
        this.account.setDavDisplayName ("fakename");
        this.account.setServerVersion ("10.0.0");
    
        this.journal_database = std.make_unique<Occ.SyncJournalDb> (local_path () + QStringLiteral (".sync_test.db"));
        this.sync_engine = std.make_unique<Occ.SyncEngine> (this.account, local_path (), remote_path, this.journal_database.get ());
        // Ignore temporary files from the download. (This is in the default exclude list, but we don't load it)
        this.sync_engine.excludedFiles ().addManualExclude (QStringLiteral ("]*.~*"));
    
        // handle aboutToRemoveAllFiles with a timeout in case our test does not handle it
        GLib.Object.connect (this.sync_engine.get (), &Occ.SyncEngine.aboutToRemoveAllFiles, this.sync_engine.get (), [this] (Occ.SyncFileItem.Direction, std.function<void (bool)> callback) {
            QTimer.singleShot (1 * 1000, this.sync_engine.get (), [callback] {
                callback (false);
            });
        });
    
        // Ensure we have a valid VfsOff instance "running"
        switch_to_vfs (this.sync_engine.syncOptions ().vfs);
    
        // A new folder will update the local file state database on first sync.
        // To have a state matching what users will encounter, we have to a sync
        // using an identical local/remote file tree first.
        ENFORCE (sync_once ());
    }

    /***********************************************************
    ***********************************************************/
    public void switch_to_vfs (unowned<Occ.Vfs> vfs);

    /***********************************************************
    ***********************************************************/
    public Occ.AccountPointer account () {
        return this.account;
    }

    /***********************************************************
    ***********************************************************/
    public Occ.SyncEngine sync_engine () {
        return this.sync_engine;
    }

    /***********************************************************
    ***********************************************************/
    public Occ.SyncJournalDb sync_journal () {
        return this.journal_database;
    }


    /***********************************************************
    ***********************************************************/
    public FileModifier local_modifier () {
        return this.local_modifier;
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo remote_modifier () {
        return this.fake_qnam.current_remote_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo current_local_state ();

    /***********************************************************
    ***********************************************************/
    public FileInfo current_remote_state () {
        return this.fake_qnam.current_remote_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo upload_state () {
        return this.fake_qnam.upload_state ();
    }

    /***********************************************************
    ***********************************************************/
    public FileInfo database_state ();

    /***********************************************************
    ***********************************************************/
    public ErrorList server_error_paths () {
        return this.fake_qnam;
    }

    /***********************************************************
    ***********************************************************/
    public void set_server_override (FakeQNAM.Override qnam_override) {
        this.fake_qnam.set_override(qnam_override);
    }

    delegate QJsonObject ReplyFunction (GLib.HashMap<string, GLib.ByteArray> map);

    /***********************************************************
    ***********************************************************/
    public QJsonObject for_each_reply_part (
        QIODevice outgoing_data,
        string content_type,
        ReplyFunction reply_function) {
        return this.fake_qnam.for_each_reply_part (outgoing_data, content_type, reply_function);
    }

    /***********************************************************
    ***********************************************************/
    public string local_path ();

    /***********************************************************
    ***********************************************************/
    public void schedule_sync ();

    /***********************************************************
    ***********************************************************/
    public void exec_until_before_propagation ();

    /***********************************************************
    ***********************************************************/
    public void exec_until_item_completed (string relative_path);

    /***********************************************************
    ***********************************************************/
    public bool exec_until_finished () {
        QSignalSpy spy = new QSignalSpy (this.sync_engine.get (), SIGNAL (on_signal_finished (bool)));
        bool ok = spy.wait (3600000);
        //  Q_ASSERT (ok && "Sync timed out");
        return spy[0][0].to_bool ();
    }

    /***********************************************************
    ***********************************************************/
    public bool sync_once () {
        schedule_sync ();
        return exec_until_finished ();
    }

    /***********************************************************
    ***********************************************************/
    private static void to_disk (QDir directory, FileInfo template_file_info);

    /***********************************************************
    ***********************************************************/
    private static void from_disk (QDir directory, FileInfo template_file_info);

}
}










void FakeFolder.switch_to_vfs (unowned<Occ.Vfs> vfs) {
    var opts = this.sync_engine.syncOptions ();

    opts.vfs.stop ();
    GLib.Object.disconnect (this.sync_engine.get (), null, opts.vfs.data (), null);

    opts.vfs = vfs;
    this.sync_engine.setSyncOptions (opts);

    Occ.VfsSetupParams vfsParams;
    vfsParams.filesystemPath = local_path ();
    vfsParams.remote_path = '/';
    vfsParams.account = this.account;
    vfsParams.journal = this.journal_database.get ();
    vfsParams.providerName = QStringLiteral ("OC-TEST");
    vfsParams.providerVersion = QStringLiteral ("0.1");
    GLib.Object.connect (this.sync_engine.get (), &GLib.Object.destroyed, vfs.data (), [vfs] () {
        vfs.stop ();
        vfs.unregisterFolder ();
    });

    vfs.on_signal_start (vfsParams);
}

FileInfo FakeFolder.current_local_state () {
    QDir root_directory ( this.temporary_directory.path ());
    FileInfo rootTemplate;
    from_disk (root_directory, rootTemplate);
    rootTemplate.fixupParentPathRecursively ();
    return rootTemplate;
}

string FakeFolder.local_path () {
    // SyncEngine wants a trailing slash
    if (this.temporary_directory.path ().endsWith ('/'))
        return this.temporary_directory.path ();
    return this.temporary_directory.path () + '/';
}

void FakeFolder.schedule_sync () {
    // Have to be done async, else, an error before exec () does not terminate the event loop.
    QMetaObject.invoke_method (this.sync_engine.get (), "startSync", Qt.QueuedConnection);
}

void FakeFolder.exec_until_before_propagation () {
    QSignalSpy spy (this.sync_engine.get (), SIGNAL (aboutToPropagate (SyncFileItemVector &)));
    //  QVERIFY (spy.wait ());
}

void FakeFolder.exec_until_item_completed (string relative_path) {
    QSignalSpy spy (this.sync_engine.get (), SIGNAL (itemCompleted (SyncFileItemPtr &)));
    QElapsedTimer t;
    t.on_signal_start ();
    while (t.elapsed () < 5000) {
        spy.clear ();
        //  QVERIFY (spy.wait ());
        for (GLib.List<GLib.Variant> args : spy) {
            var item = args[0].value<Occ.SyncFileItemPtr> ();
            if (item.destination () == relative_path)
                return;
        }
    }
    //  QVERIFY (false);
}

void FakeFolder.to_disk (QDir directory, FileInfo template_file_info) {
    foreach (FileInfo child, template_file_info.children) {
        if (child.isDir) {
            QDir subDir (directory);
            directory.mkdir (child.name);
            subDir.cd (child.name);
            to_disk (subDir, child);
        } else {
            GLib.File file = new GLib.File (directory.filePath (child.name));
            file.open (GLib.File.WriteOnly);
            file.write (GLib.ByteArray {}.fill (child.content_char, child.size));
            file.close ();
            Occ.FileSystem.set_modification_time (file.filename (), Occ.Utility.qDateTimeToTime_t (child.last_modified));
        }
    }
}

void FakeFolder.from_disk (QDir directory, FileInfo template_file_info) {
    foreach (GLib.FileInfo diskChild, directory.entryInfoList (QDir.AllEntries | QDir.NoDotAndDotDot)) {
        if (diskChild.isDir ()) {
            QDir subDir = directory;
            subDir.cd (diskChild.filename ());
            FileInfo subFi = template_file_info.children[diskChild.filename ()] = FileInfo ( diskChild.filename ());
            from_disk (subDir, subFi);
        } else {
            GLib.File f ( diskChild.filePath ());
            f.open (GLib.File.ReadOnly);
            var content = f.read (1);
            if (content.size () == 0) {
                qWarning ("Empty file at:" + diskChild.filePath ();
                continue;
            }
            char content_char = content.at (0);
            template_file_info.children.insert (diskChild.filename (), FileInfo ( diskChild.filename (), diskChild.size (), content_char });
        }
    }
}

static FileInfo findOrCreateDirs (FileInfo base, PathComponents components) {
    if (components.isEmpty ())
        return base;
    var childName = components.pathRoot ();
    var it = base.children.find (childName);
    if (it != base.children.end ()) {
        return findOrCreateDirs (*it, components.sub_components ());
    }
    var newDir = base.children[childName] = FileInfo ( childName };
    newDir.parentPath = base.path ();
    return findOrCreateDirs (newDir, components.sub_components ());
}

FileInfo FakeFolder.database_state () {
    FileInfo result;
    this.journal_database.getFilesBelowPath ("", [&] (Occ.SyncJournalFileRecord record) {
        var components = PathComponents (record.path ());
        var parentDir = findOrCreateDirs (result, components.parentDirComponents ());
        var name = components.filename ();
        var item = parentDir.children[name];
        item.name = name;
        item.parentPath = parentDir.path ();
        item.size = record.fileSize;
        item.isDir = record.type == ItemTypeDirectory;
        item.permissions = record.remotePerm;
        item.etag = record.etag;
        item.last_modified = Occ.Utility.qDateTimeFromTime_t (record.modtime);
        item.file_identifier = record.file_identifier;
        item.checksums = record.checksumHeader;
        // item.content_char can't be set from the database
    });
    return result;
}