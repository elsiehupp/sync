/***********************************************************
@author Cédric Bellegarde <gnumdk@gmail.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Cursor>
//  #include <GLib.Application>
//  #include <GLib.QmlApplicationEngine>
//  #include <GLib.Qml_context>
//  #include <GLib.Quick_window>
//  #include <Gdk.Monitor>
//  #include <GLib.Menu>

//  #ifdef USE_FDO_NOTIFICATIONS
//  #include <GLib.DBusConnection>
//  #include <GLib.DBusInterface>
//  #include <GLib.DBus_message>
//  #include <GLib.DBus_pending_call>
//  #endif

//  #include <GLib.SystemTrayIcon>
//  #include <GLib.QmlNetworkAccessManagerFactory>

namespace Occ {
namespace Ui {


/***********************************************************
@brief The Systray class
@ingroup gui
***********************************************************/
public class Systray { //: GLib.SystemTrayIcon {

    //  const string NOTIFICATIONS_SERVICE = "org.freedesktop.Notifications";
    //  const string NOTIFICATIONS_PATH = "/org/freedesktop/Notifications";
    //  const string NOTIFICATIONS_IFACE = "org.freedesktop.Notifications";

    //  class AccessManagerFactory { //: Soup.Factory {

        //  /***********************************************************
        //  ***********************************************************/
        //  public AccessManagerFactory () {
        //      base ();
        //  }

        //  /***********************************************************
        //  ***********************************************************/
        //  public override Soup.ClientContext create () {
        //      return new Soup.ClientContext (parent);
        //  }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public enum TaskBarPosition {
        //  BOTTOM,
        //  LEFT,
        //  TOP,
        //  RIGHT
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  static Systray instance {
        //  public get {
        //      if (!this.instance) {
        //          this.instance = new Systray ();
        //      }
        //      return this.instance;
        //  }
        //  private set {
        //      this.instance = value;
        //  }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public bool is_open { public get; private set; }
    //  public bool sync_is_paused { public get; private set; }

    //  public GLib.QmlApplicationEngine tray_engine {
        //  private get {
        //      return this.tray_engine;
        //  }
        //  public set {
        //      this.tray_engine = value;

        //      this.tray_engine.network_access_manager_factory (this.access_manager_factory);

        //      this.tray_engine.add_import_path ("qrc:/qml/theme");
        //      this.tray_engine.add_ImageProvider ("avatars", new ImageProvider ());
        //      this.tray_engine.add_ImageProvider ("svgimage-custom-color", new SvgImageProvider ());
        //      this.tray_engine.add_ImageProvider ("unified-search-result-icon", new UnifiedSearchResultImageProvider ());
        //  }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  private AccessManagerFactory access_manager_factory;


    //  internal signal void signal_current_user_changed ();
    //  internal signal void signal_open_account_wizard ();
    //  internal signal void signal_open_main_dialog ();
    //  internal signal void signal_open_settings ();
    //  internal signal void signal_open_help ();
    //  internal signal void signal_shutdown ();

    //  internal signal void hide_window ();
    //  internal signal void signal_show_window ();
    //  internal signal void open_share_dialog (string share_path, string local_path);
    //  internal signal void show_file_activity_dialog (string share_path, string local_path);


    //  private Systray () {
        //  base ();
        //  this.is_open = false;
        //  this.sync_is_paused = true;

        //  qml_register_singleton_type<UserModel> (
        //      "com.nextcloud.desktopclient",
        //      1,
        //      0,
        //      "UserModel",
        //      on_signal_user_model_instance_for_engineon_signal_instance_for_engine
        //  );

        //  qml_register_singleton_type<UserAppsModel> (
        //      "com.nextcloud.desktopclient",
        //      1,
        //      0,
        //      "UserAppsModel",
        //      on_signal_user_apps_model_instance_for_engineon_signal_instance_for_engine
        //  );

        //  qml_register_singleton_type<Systray> (
        //      "com.nextcloud.desktopclient",
        //      1,
        //      0,
        //      "Theme",
        //      on_signal_theme_instance_for_engineon_signal_instance_for_engine
        //  );

        //  qml_register_singleton_type<Systray> (
        //      "com.nextcloud.desktopclient",
        //      1,
        //      0,
        //      "Systray",
        //      on_signal_systray_instance_for_engineon_signal_instance_for_engine
        //  );

        //  qml_register_type<WheelHandler> ("com.nextcloud.desktopclient", 1, 0, "WheelHandler");

        //  var context_menu = new GLib.Menu ();
        //  if (AccountManager.instance.accounts == "") {
        //      context_menu.add_action (_("Add account"), this, Systray.signal_open_account_wizard);
        //  } else {
        //      context_menu.add_action (_("Open main dialog"), this, Systray.signal_open_main_dialog);
        //  }

        //  var pause_action = context_menu.add_action (_("Pause sync"), this, Systray.on_signal_pause_all_folders);
        //  var resume_action = context_menu.add_action (_("Resume sync"), this, Systray.on_signal_unpause_all_folders);
        //  context_menu.add_action (_("Settings"), this, Systray.signal_open_settings);
        //  context_menu.add_action (_("Exit %1").printf (LibSync.Theme.app_name_gui), this, Systray.signal_shutdown);
        //  context_menu (context_menu);

        //  context_menu.about_to_show.connect (
        //      on_signal_context_menu_about_to_show
        //  );

        //  UserModel.instance.signal_new_user_selected.connect (
        //      this.on_signal_new_user_selected
        //  );
        //  UserModel.instance.signal_add_account.connect (
        //      this.signal_open_account_wizard
        //  );
        //  AccountManager.instance.signal_account_added.connect (
        //      this.show_window
        //  );
    //  }


    //  private UserModel on_signal_user_model_instance_for_engineon_signal_instance_for_engine (GLib.QmlEngine qml_engine, GLib.JSEngine qjs_engine) {
        //  return UserModel.instance;
    //  }


    //  private UserAppsModel on_signal_user_apps_model_instance_for_engineon_signal_instance_for_engine (GLib.QmlEngine qml_engine, GLib.JSEngine qjs_engine) {
        //  return UserAppsModel.instance;
    //  }


    //  private LibSync.Theme on_signal_theme_instance_for_engineon_signal_instance_for_engine (GLib.QmlEngine qml_engine, GLib.JSEngine qjs_engine) {
        //  return LibSync.Theme.instance;
    //  }


    //  private Systray on_signal_systray_instance_for_engineon_signal_instance_for_engine (GLib.QmlEngine qml_engine, GLib.JSEngine qjs_engine) {
        //  return Systray.instance;
    //  }


    //  private void on_signal_context_menu_about_to_show () {
        //  var folders = FolderManager.instance.map ();

        //  GLib.List<FolderConnection> all_paused = new GLib.List<FolderConnection> ();

        //  foreach (FolderConnection folder_connection in folders) {
        //      if (folder_connection.sync_paused) {
        //          all_paused.append (folder_connection);
        //      }
        //  }

        //  string pause_text = folders.size () > 1 ? _("Pause sync for all") : _("Pause sync");
        //  pause_action.on_signal_text (pause_text);
        //  pause_action.visible (!all_paused);
        //  pause_action.enabled (!all_paused);

        //  GLib.List<FolderConnection> any_paused = new GLib.List<FolderConnection> ();

        //  foreach (FolderConnection folder_connection in folders) {
        //      if (folder_connection.sync_paused) {
        //          any_paused.append (folder_connection);
        //      }
        //  }

        //  string resume_text = folders.size () > 1 ? _("Resume sync for all") : _("Resume sync");
        //  resume_action.on_signal_text (resume_text);
        //  resume_action.visible (any_paused);
        //  resume_action.enabled (any_paused);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void create () {
        //  if (this.tray_engine != null) {
        //      if (AccountManager.instance.accounts.length () != 0) {
        //          this.tray_engine.root_context ().context_property ("activity_model", UserModel.instance.current_activity_model);
        //      }
        //      this.tray_engine.on_signal_load ("qrc:/qml/src/gui/tray/Window.qml");
        //  }
        //  hide_window ();
        //  signal_activated (GLib.SystemTrayIcon.Activation_reason.Unknown);

        //  var folder_map = FolderManager.instance.map ();
        //  foreach (var folder_connection in folder_map) {
        //      if (!folder_connection.sync_paused) {
        //          this.sync_is_paused = false;
        //          break;
        //      }
        //  }
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public void show_message (string title, string message, MessageIcon icon) {
        //  if (GLib.DBusInterface (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE).is_valid) {
        //      GLib.HashMap hints = {{"desktop-entry", LINUX_APPLICATION_ID}};
        //      GLib.List<GLib.Variant> args = {
        //          APPLICATION_NAME,
        //          (uint32)0,
        //          APPLICATION_ICON_NAME.
        //          title.
        //          message.
        //          { },
        //          hints,
        //          (int32)-1
        //      };
        //      GLib.DBus_message method = GLib.DBus_message.create_method_call (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE, "Notify");
        //      method.arguments (args);
        //      GLib.DBusConnection.session_bus ().async_call (method);
        //  } else {
        //      GLib.SystemTrayIcon.show_message (title, message, icon);
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public string window_title () {
        //  return LibSync.Theme.app_name_gui;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public bool use_normal_window () {
        //  if (!is_system_tray_available ()) {
        //      return true;
        //  }

        //  LibSync.ConfigFile config;
        //  return config.show_main_dialog_as_normal_window ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void pause_resume_sync () {
        //  if (this.sync_is_paused) {
        //      this.sync_is_paused = false;
        //      on_signal_unpause_all_folders ();
        //  } else {
        //      this.sync_is_paused = true;
        //      on_signal_pause_all_folders ();
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void tool_tip (string tip) {
        //  GLib.SystemTrayIcon.tool_tip (_("%1 : %2").printf (LibSync.Theme.app_name_gui, tip));
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void opened () {
        //  this.is_open = true;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void closed () {
        //  this.is_open = false;
    //  }


    //  /***********************************************************
    //  Helper functions for cross-platform tray icon position and
    //  taskbar orientation detection
    //  ***********************************************************/


    //  /***********************************************************
    //  ***********************************************************/
    //  public void position_window (GLib.Quick_window window) {
        //  if (!use_normal_window ()) {
        //      window.screen (current_screen ());
        //      var position = compute_window_position (window.width (), window.height ());
        //      window.position (position);
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void force_window_init (GLib.Quick_window window) {
        //  // HACK : At least on Windows, if the systray window is not shown at least once
        //  // it can prevent session handling to carry on properly, so we show/hide it here
        //  // this shouldn't flicker
        //  window.show ();
        //  window.hide ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public void on_signal_new_user_selected () {
        //  if (this.tray_engine) {
        //      // Change Activity_model
        //      this.tray_engine.root_context ().context_property ("activity_model", UserModel.instance.current_activity_model);
        //  }

        //  // Rebuild App list
        //  UserAppsModel.instance.build_app_list ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_unpause_all_folders () {
        //  pause_on_signal_all_folders_helper (false);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_pause_all_folders () {
        //  pause_on_signal_all_folders_helper (true);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void pause_on_signal_all_folders_helper (bool pause) {
        //  var folders = FolderManager.instance.map ();
        //  foreach (var folder_connection in folders) {
        //      if (accounts.contains (folder_connection.account_state)) {
        //          folder_connection.sync_paused (pause);
        //          if (pause) {
        //              folder_connection.on_signal_terminate_sync ();
        //          }
        //      }
        //  }
    //  }



    //  /***********************************************************
    //  For some reason we get the raw pointer from FolderConnection.account_state
    //  that's why we need a list of raw pointers for the call to
    //  contains later on...
    //  ***********************************************************/
    //  private static AccountState accounts () {
        //  GLib.List<AccountState> account_state_list = new GLib.List<AccountState> ();
        //  foreach (AccountState account in AccountManager.instance.accounts) {
        //      account_state_list.append (account);
        //  }
        //  return account_state_list;
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private Gdk.Monitor current_screen () {
        //  var screens = GLib.Application.screens ();
        //  var cursor_pos = GLib.Cursor.position ();

        //  foreach (var screen in screens) {
        //      if (screen.geometry ().contains (cursor_pos)) {
        //          return screen;
        //      }
        //  }

        //  // Didn't find anything matching the cursor position,
        //  // falling back to the primary screen
        //  return Gdk.Display.get_default ().get_default_screen ().get_primary_monitor ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.Rect current_screen_rect () {
        //  var screen = current_screen ();
        //  //  GLib.assert_true (screen);
        //  return screen.geometry ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.Point compute_window_reference_point () {
        //  int spacing = 4;
        //  var tray_icon_center = calc_tray_icon_center ();
        //  var taskbar_rect = taskbar_geometry ();
        //  var taskbar_screen_edge = taskbar_orientation ();
        //  var screen_rect = current_screen_rect ();

        //  GLib.debug ("screen_rect: " + screen_rect);
        //  GLib.debug ("taskbar_rect: " + taskbar_rect);
        //  GLib.debug ("taskbar_screen_edge: " + taskbar_screen_edge);
        //  GLib.debug ("tray_icon_center: " + tray_icon_center);

        //  switch (taskbar_screen_edge) {
        //  case TaskBarPosition.BOTTOM:
        //      return new GLib.Point (
        //          tray_icon_center.x (),
        //          screen_rect.bottom () - taskbar_rect.height () - spacing
        //      );
        //  case TaskBarPosition.LEFT:
        //      return new GLib.Point (
        //          screen_rect.left () + taskbar_rect.width () + spacing,
        //          tray_icon_center.y ()
        //      );
        //  case TaskBarPosition.TOP:
        //      return new GLib.Point (
        //          tray_icon_center.x (),
        //          screen_rect.top () + taskbar_rect.height () + spacing
        //      );
        //  case TaskBarPosition.RIGHT:
        //      return new GLib.Point (
        //          screen_rect.right () - taskbar_rect.width () - spacing,
        //          tray_icon_center.y ()
        //      );
        //  }
        //  GLib.assert_not_reached ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.Point calc_tray_icon_center () {
        //  // On Linux, fall back to mouse position (assuming tray icon is activated by mouse click)
        //  return GLib.Cursor.position (current_screen ());
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private TaskBarPosition taskbar_orientation () {
        //  var screen_rect = current_screen_rect ();
        //  var tray_icon_center = calc_tray_icon_center ();

        //  var dist_bottom = screen_rect.bottom () - tray_icon_center.y ();
        //  var dist_right = screen_rect.right () - tray_icon_center.x ();
        //  var dist_left = tray_icon_center.x () - screen_rect.left ();
        //  var dist_top = tray_icon_center.y () - screen_rect.top ();

        //  var min_dist = std.min ({dist_right, dist_top, dist_bottom});

        //  if (min_dist == dist_bottom) {
        //      return TaskBarPosition.BOTTOM;
        //  } else if (min_dist == dist_left) {
        //      return TaskBarPosition.LEFT;
        //  } else if (min_dist == dist_top) {
        //      return TaskBarPosition.TOP;
        //  } else {
        //      return TaskBarPosition.RIGHT;
        //  }
    //  }


    //  /***********************************************************
    //  TODO: Get real taskbar dimensions on Linux as well
    //  ***********************************************************/
    //  private GLib.Rect taskbar_geometry () {
        //  if (taskbar_orientation () == TaskBarPosition.BOTTOM || taskbar_orientation () == TaskBarPosition.TOP) {
        //      var screen_width = current_screen_rect ().width ();
        //      return {0, 0, screen_width, 32};
        //  } else {
        //      var screen_height = current_screen_rect ().height ();
        //      return {0, 0, 32, screen_height};
        //  }
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private GLib.Point compute_window_position (int width, int height) {
        //  var reference_point = compute_window_reference_point ();

        //  TaskBarPosition taskbar_screen_edge = taskbar_orientation ();
        //  var screen_rect = current_screen_rect ();

        //  GLib.Point bottom_right = top_left (reference_point) + GLib.Point (width, height);

        //  GLib.debug ("taskbar_screen_edge: " + taskbar_screen_edge.to_string ());
        //  GLib.debug ("screen_rect: " + screen_rect.to_string ());
        //  GLib.debug ("window_rect (reference) " + GLib.Rect (top_left (reference_point), bottom_right).to_string ());
        //  GLib.debug ("window_rect (adjusted) " + window_rect.to_string ());

        //  return window_rect (
        //      screen_rect,
        //      reference_point,
        //      bottom_right
        //  ).top_left (
        //      taskbar_screen_edge,
        //      reference_point,
        //      bottom_right,
        //      width,
        //      height
        //  );
    //  }


    //  private static GLib.Point top_left (
        //  TaskBarPosition taskbar_screen_edge,
        //  GLib.Point reference_point,
        //  GLib.Point bottom_right,
        //  int width,
        //  int height
    //  ) {
        //  switch (taskbar_screen_edge) {
        //  case TaskBarPosition.BOTTOM:
        //      return reference_point - GLib.Point (width / 2, height);
        //  case TaskBarPosition.LEFT:
        //      return reference_point;
        //  case TaskBarPosition.TOP:
        //      return reference_point - GLib.Point (width / 2, 0);
        //  case TaskBarPosition.RIGHT:
        //      return reference_point - GLib.Point (width, 0);
        //  }
        //  GLib.assert_not_reached ();
    //  }


    //  private static GLib.Rect window_rect (GLib.Rect screen_rect, GLib.Point reference_point, GLib.Point bottom_right) {
        //  GLib.Rect rect = GLib.Rect (top_left (reference_point), bottom_right);
        //  var offset = GLib.Point ();

        //  if (rect.left () < screen_rect.left ()) {
        //      offset.x (screen_rect.left () - rect.left () + 4);
        //  } else if (rect.right () > screen_rect.right ()) {
        //      offset.x (screen_rect.right () - rect.right () - 4);
        //  }

        //  if (rect.top () < screen_rect.top ()) {
        //      offset.y (screen_rect.top () - rect.top () + 4);
        //  } else if (rect.bottom () > screen_rect.bottom ()) {
        //      offset.y (screen_rect.bottom () - rect.bottom () - 4);
        //  }

        //  return rect.translated (offset);
    //  }

} // class Systray

} // namespace Ui
} // namespace Occ
