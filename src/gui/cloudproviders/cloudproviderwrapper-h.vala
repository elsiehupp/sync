/*
Copyright (C) by Julius Härtl <jus@bitgrid.net>

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

/* Forward declaration required since gio header files interfere with GLib.Object headers */
struct _CloudProvidersProviderExporter;
using CloudProvidersProviderExporter = _CloudProvidersProviderExporter;
struct _CloudProvidersAccountExporter;
using CloudProvidersAccountExporter = _CloudProvidersAccountExporter;
struct _GMenuModel;
using GMenuModel = _GMenuModel;
struct _GMenu;
using GMenu = _GMenu;
struct _GActionGroup;
using GActionGroup = _GActionGroup;
using gchar = char;
using gpointer = void*;

using namespace Occ;

class CloudProviderWrapper : GLib.Object {
public:
    CloudProviderWrapper (GLib.Object *parent = nullptr, Folder *folder = nullptr, int folderId = 0, CloudProvidersProviderExporter* cloudprovider = nullptr);
    ~CloudProviderWrapper () override;
    CloudProvidersAccountExporter* accountExporter ();
    Folder* folder ();
    GMenuModel* getMenuModel ();
    GActionGroup* getActionGroup ();
    void updateStatusText (QString statusText);
    void updatePauseStatus ();

public slots:
    void slotSyncStarted ();
    void slotSyncFinished (SyncResult &);
    void slotUpdateProgress (QString &folder, ProgressInfo &progress);
    void slotSyncPausedChanged (Folder*, bool);

private:
    Folder *_folder;
    CloudProvidersProviderExporter *_cloudProvider;
    CloudProvidersAccountExporter *_cloudProviderAccount;
    QList<QPair<QString, QString>> _recentlyChanged;
    bool _paused;
    GMenu* _mainMenu = nullptr;
    GMenu* _recentMenu = nullptr;
};
