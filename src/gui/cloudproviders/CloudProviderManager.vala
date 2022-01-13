/***********************************************************
Copyright (C) by Julius Härtl <jus@bitgrid.net>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>

using namespace Occ;


class CloudProviderManager : GLib.Object {
public:
    CloudProviderManager (GLib.Object *parent = nullptr);
    void registerSignals ();

signals:

public slots:
    void slotFolderListChanged (Folder.Map &folderMap);

private:
    QMap<string, CloudProviderWrapper> _map;
    unsigned int _folder_index;
};








/***********************************************************
Copyright (C) by Julius Härtl <jus@bitgrid.net>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <glib.h>
// #include <gio/gio.h>
// #include <cloudprovidersproviderexporter.h>

CloudProvidersProviderExporter *_providerExporter;

void on_name_acquired (GDBusConnection *connection, gchar *name, gpointer user_data) {
    Q_UNUSED (name);
    CloudProviderManager *self;
    self = static_cast<CloudProviderManager> (user_data);
    _providerExporter = cloud_providers_provider_exporter_new (connection, LIBCLOUDPROVIDERS_DBUS_BUS_NAME, LIBCLOUDPROVIDERS_DBUS_OBJECT_PATH);
    cloud_providers_provider_exporter_set_name (_providerExporter, APPLICATION_NAME);
    self.registerSignals ();
}

void on_name_lost (GDBusConnection *connection, gchar *name, gpointer user_data) {
    Q_UNUSED (connection);
    Q_UNUSED (name);
    Q_UNUSED (user_data);
    g_clear_object (&_providerExporter);
}

void CloudProviderManager.registerSignals () {
    Occ.FolderMan *folderManager = Occ.FolderMan.instance ();
    connect (folderManager, SIGNAL (folderListChanged (Folder.Map &)), SLOT (slotFolderListChanged (Folder.Map &)));
    slotFolderListChanged (folderManager.map ());
}

CloudProviderManager.CloudProviderManager (GLib.Object *parent) : GLib.Object (parent) {
    _folder_index = 0;
    g_bus_own_name (G_BUS_TYPE_SESSION, LIBCLOUDPROVIDERS_DBUS_BUS_NAME, G_BUS_NAME_OWNER_FLAGS_NONE, nullptr, on_name_acquired, nullptr, this, nullptr);
}

void CloudProviderManager.slotFolderListChanged (Folder.Map &folderMap) {
    QMapIterator<string, CloudProviderWrapper> i (_map);
    while (i.hasNext ()) {
        i.next ();
        if (!folderMap.contains (i.key ())) {
            cloud_providers_provider_exporter_remove_account (_providerExporter, i.value ().accountExporter ());
            delete _map.find (i.key ()).value ();
            _map.remove (i.key ());
        }
    }

    Folder.MapIterator j (folderMap);
    while (j.hasNext ()) {
        j.next ();
        if (!_map.contains (j.key ())) {
            auto *cpo = new CloudProviderWrapper (this, j.value (), _folder_index++, _providerExporter);
            _map.insert (j.key (), cpo);
        }
    }
}
