/***********************************************************
Copyright (C) by Julius Härtl <jus@bitgrid.net>

<GPLv3-or-later-Boilerplate>
***********************************************************/
//  #include <cloudprovidersproviderexporter.h>

CloudProvidersProviderExporter this.provider_exporter;

using namespace Occ;


class CloudProviderManager : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public CloudProviderManager (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void on_signal_folder_list_changed (Folder.Map folder_map);


    /***********************************************************
    ***********************************************************/
    private GLib.HashMap<string, CloudProviderWrapper> this.map;
    private uint32 this.folder_index;
}









void on_signal_name_acquired (GDBusConnection connection, gchar name, gpointer user_data) {
    //  Q_UNUSED (name);
    CloudProviderManager self;
    self = static_cast<CloudProviderManager> (user_data);
    this.provider_exporter = cloud_providers_provider_exporter_new (connection, LIBCLOUDPROVIDERS_DBUS_BUS_NAME, LIBCLOUDPROVIDERS_DBUS_OBJECT_PATH);
    cloud_providers_provider_exporter_name (this.provider_exporter, APPLICATION_NAME);
    self.register_signals ();
}

void on_signal_name_lost (GDBusConnection connection, gchar name, gpointer user_data) {
    //  Q_UNUSED (connection);
    //  Q_UNUSED (name);
    //  Q_UNUSED (user_data);
    g_clear_object (&this.provider_exporter);
}

void CloudProviderManager.register_signals () {
    Occ.FolderMan folder_manager = Occ.FolderMan.instance ();
    connect (folder_manager, SIGNAL (folder_list_changed (Folder.Map &)), SLOT (on_signal_folder_list_changed (Folder.Map &)));
    on_signal_folder_list_changed (folder_manager.map ());
}

CloudProviderManager.CloudProviderManager (GLib.Object parent) : GLib.Object (parent) {
    this.folder_index = 0;
    g_bus_own_name (G_BUS_TYPE_SESSION, LIBCLOUDPROVIDERS_DBUS_BUS_NAME, G_BUS_NAME_OWNER_FLAGS_NONE, null, on_signal_name_acquired, null, this, null);
}

void CloudProviderManager.on_signal_folder_list_changed (Folder.Map folder_map) {
    QMapIterator<string, CloudProviderWrapper> i (this.map);
    while (i.has_next ()) {
        i.next ();
        if (!folder_map.contains (i.key ())) {
            cloud_providers_provider_exporter_remove_account (this.provider_exporter, i.value ().account_exporter ());
            delete this.map.find (i.key ()).value ();
            this.map.remove (i.key ());
        }
    }

    Folder.MapIterator j (folder_map);
    while (j.has_next ()) {
        j.next ();
        if (!this.map.contains (j.key ())) {
            var cpo = new CloudProviderWrapper (this, j.value (), this.folder_index++, this.provider_exporter);
            this.map.insert (j.key (), cpo);
        }
    }
}
