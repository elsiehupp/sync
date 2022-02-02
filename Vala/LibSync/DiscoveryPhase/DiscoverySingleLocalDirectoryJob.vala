/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using CSync;
namespace Occ {

/***********************************************************
@brief Run list on a local directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleLocalDirectoryJob : GLib.Object, public QRunnable {

    /***********************************************************
    ***********************************************************/
    public DiscoverySingleLocalDirectoryJob (AccountPointer account, string local_path, Occ.Vfs vfs, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public void run () override;
signals:
    void on_finished (GLib.Vector<LocalInfo> result);
    void finished_fatal_error (string error_string);
    void finished_non_fatal_error (string error_string);

    void item_discovered (SyncFileItemPtr item);
    void child_ignored (bool b);

    /***********************************************************
    ***********************************************************/
    private string this.local_path;
    private AccountPointer this.account;
    private Occ.Vfs* this.vfs;

};