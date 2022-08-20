/***********************************************************
@author 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.WizardPage>

namespace Occ {
namespace Ui {

public class WelcomePage { //: GLib.WizardPage {

//    /***********************************************************
//    ***********************************************************/
//    private WelcomePage instance;

//    /***********************************************************
//    ***********************************************************/
//    private OwncloudWizard oc_wizard;

//    /***********************************************************
//    ***********************************************************/
//    private WizardCommon.Pages next_page = WizardCommon.Pages.PAGE_SERVER_SETUP;

//    /***********************************************************
//    ***********************************************************/
//    public WelcomePage (OwncloudWizard oc_wizard) {
//        base ();
//        this.instance = new WelcomePage ();
//        this.oc_wizard = oc_wizard;
//        this.up_ui ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    public int next_id {
//        public get {
//            return this.next_page;
//        }
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void initialize_page () {
//        customize_style ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    public void login_button_default () {
//        this.instance.login_button.default (true);
//        this.instance.login_button.focus ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void up_ui () {
//        this.instance.up_ui (this);
//        set_up_slide_show ();
//        set_up_login_button ();
//        set_up_create_account_button ();
//        set_up_host_your_own_server_label ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void customize_style () {
//        style_slide_show ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void style_slide_show () {
//        var theme = LibSync.Theme.instance;
//        var background_color = palette ().window ().color ();

//        var wizard_nextcloud_icon_filename = theme.is_branded ? LibSync.Theme.hidpi_filename ("wizard-nextcloud.png", background_color)
//                                                                    : LibSync.Theme.hidpi_filename (":/client/theme/colored/wizard-nextcloud.png");
//        var wizard_files_icon_filename = theme.is_branded ? LibSync.Theme.hidpi_filename ("wizard-files.png", background_color)
//                                                                : LibSync.Theme.hidpi_filename (":/client/theme/colored/wizard-files.png");
//        var wizard_groupware_icon_filename = theme.is_branded ? LibSync.Theme.hidpi_filename ("wizard-groupware.png", background_color)
//                                                                    : LibSync.Theme.hidpi_filename (":/client/theme/colored/wizard-groupware.png");
//        var wizard_talk_icon_filename = theme.is_branded ? LibSync.Theme.hidpi_filename ("wizard-talk.png", background_color)
//                                                               : LibSync.Theme.hidpi_filename (":/client/theme/colored/wizard-talk.png");

//        this.instance.slide_show.add_slide (wizard_nextcloud_icon_filename, _("Keep your data secure and under your control"));
//        this.instance.slide_show.add_slide (wizard_files_icon_filename, _("Secure collaboration & file exchange"));
//        this.instance.slide_show.add_slide (wizard_groupware_icon_filename, _("Easy-to-use web mail, calendaring & contacts"));
//        this.instance.slide_show.add_slide (wizard_talk_icon_filename, _("Screensharing, online meetings & web conferences"));

//        bool is_dark_background = LibSync.Theme.is_dark_color (background_color);
//        this.instance.slide_show_next_button.icon (theme.ui_theme_icon ("control-next.svg", is_dark_background));
//        this.instance.slide_show_previous_button.icon (theme.ui_theme_icon ("control-prev.svg", is_dark_background));
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void set_up_slide_show () {
//        this.instance.slide_show.clicked.connect (
//            this.instance.slide_show.on_signal_stop_show
//        );
//        this.instance.slide_show_next_button.clicked.connect (
//            this.instance.slide_show.on_signal_next_slide
//        );
//        this.instance.slide_show_previous_button.clicked.connect (
//            this.instance.slide_show.on_signal_prev_slide
//        );
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void set_up_login_button () {
//        string app_name = LibSync.Theme.app_name_gui;

//        this.instance.login_button.on_signal_text (_("Log in to your %1").printf (app_name));
//        this.instance.login_button.clicked.connect (
//            this.on_login_button_clicked
//        );
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_login_button_clicked (bool checked) {
//        this.next_page = WizardCommon.Pages.PAGE_SERVER_SETUP;
//        this.oc_wizard.next ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void set_up_create_account_button () {
//        this.instance.create_account_button.clicked.connect (
//            this.on_create_account_button_clicked
//        );
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_create_account_button_clicked (bool checked) {
//    //  #ifdef WITH_WEBENGINE
//        this.oc_wizard.registration (true);
//        this.next_page = WizardCommon.Pages.PAGE_WEB_VIEW;
//        this.oc_wizard.next ();
//    //  #else // WITH_WEBENGINE
//        this.oc_wizard.registration (true);
//        OpenExternal.open_browser ("https://nextcloud.com/register");
//    //  #endif // WITH_WEBENGINE
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void set_up_host_your_own_server_label () {
//        this.instance.host_your_own_server_label.on_signal_text (_("Host your own server"));
//        this.instance.host_your_own_server_label.alignment (GLib.AlignCenter);
//        this.instance.host_your_own_server_label.url (GLib.Uri ("https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation"));
//    }

} // class WelcomePage

} // namespace Ui
} // namespace Occ
