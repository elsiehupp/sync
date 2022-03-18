/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QWizardPage>

namespace Occ {
namespace Ui {

public class WelcomePage : QWizardPage {

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<Ui.WelcomePage> ui;

    /***********************************************************
    ***********************************************************/
    private OwncloudWizard oc_wizard;

    /***********************************************************
    ***********************************************************/
    private WizardCommon.Pages next_page = WizardCommon.Pages.PAGE_SERVER_SETUP;

    /***********************************************************
    ***********************************************************/
    public WelcomePage (OwncloudWizard oc_wizard) {
        base ();
        this.ui = new Ui.WelcomePage ();
        this.oc_wizard = oc_wizard;
        this.up_ui ();
    }


    /***********************************************************
    ***********************************************************/
    public int next_id {
        public get {
            return this.next_page;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    public void login_button_default () {
        this.ui.login_button.default (true);
        this.ui.login_button.focus ();
    }


    /***********************************************************
    ***********************************************************/
    private void up_ui () {
        this.ui.up_ui (this);
        set_up_slide_show ();
        set_up_login_button ();
        set_up_create_account_button ();
        set_up_host_your_own_server_label ();
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        style_slide_show ();
    }


    /***********************************************************
    ***********************************************************/
    private void style_slide_show () {
        const var theme = Theme.instance;
        const var background_color = palette ().window ().color ();

        const var wizard_nextcloud_icon_filename = theme.is_branded ? Theme.hidpi_filename ("wizard-nextcloud.png", background_color)
                                                                    : Theme.hidpi_filename (":/client/theme/colored/wizard-nextcloud.png");
        const var wizard_files_icon_filename = theme.is_branded ? Theme.hidpi_filename ("wizard-files.png", background_color)
                                                                : Theme.hidpi_filename (":/client/theme/colored/wizard-files.png");
        const var wizard_groupware_icon_filename = theme.is_branded ? Theme.hidpi_filename ("wizard-groupware.png", background_color)
                                                                    : Theme.hidpi_filename (":/client/theme/colored/wizard-groupware.png");
        const var wizard_talk_icon_filename = theme.is_branded ? Theme.hidpi_filename ("wizard-talk.png", background_color)
                                                               : Theme.hidpi_filename (":/client/theme/colored/wizard-talk.png");

        this.ui.slide_show.add_slide (wizard_nextcloud_icon_filename, _("Keep your data secure and under your control"));
        this.ui.slide_show.add_slide (wizard_files_icon_filename, _("Secure collaboration & file exchange"));
        this.ui.slide_show.add_slide (wizard_groupware_icon_filename, _("Easy-to-use web mail, calendaring & contacts"));
        this.ui.slide_show.add_slide (wizard_talk_icon_filename, _("Screensharing, online meetings & web conferences"));

        const bool is_dark_background = Theme.is_dark_color (background_color);
        this.ui.slide_show_next_button.icon (theme.ui_theme_icon ("control-next.svg", is_dark_background));
        this.ui.slide_show_previous_button.icon (theme.ui_theme_icon ("control-prev.svg", is_dark_background));
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_slide_show () {
        this.ui.slide_show.clicked.connect (
            this.ui.slide_show.on_signal_stop_show
        );
        this.ui.slide_show_next_button.clicked.connect (
            this.ui.slide_show.on_signal_next_slide
        );
        this.ui.slide_show_previous_button.clicked.connect (
            this.ui.slide_show.on_signal_prev_slide
        );
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_login_button () {
        const string app_name = Theme.app_name_gui;

        this.ui.login_button.on_signal_text (_("Log in to your %1").printf (app_name));
        this.ui.login_button.clicked.connect (
            this.on_login_button_clicked
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_login_button_clicked (bool checked) {
        this.next_page = WizardCommon.Pages.PAGE_SERVER_SETUP;
        this.oc_wizard.next ();
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_create_account_button () {
        this.ui.create_account_button.clicked.connect (
            this.on_create_account_button_clicked
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_create_account_button_clicked (bool checked) {
    //  #ifdef WITH_WEBENGINE
        this.oc_wizard.registration (true);
        this.next_page = WizardCommon.Pages.PAGE_WEB_VIEW;
        this.oc_wizard.next ();
    //  #else // WITH_WEBENGINE
        this.oc_wizard.registration (true);
        OpenExternal.open_browser ("https://nextcloud.com/register");
    //  #endif // WITH_WEBENGINE
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_host_your_own_server_label () {
        this.ui.host_your_own_server_label.on_signal_text (_("Host your own server"));
        this.ui.host_your_own_server_label.alignment (Qt.AlignCenter);
        this.ui.host_your_own_server_label.url (GLib.Uri ("https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation"));
    }

} // class WelcomePage

} // namespace Ui
} // namespace Occ
