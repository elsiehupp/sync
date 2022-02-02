/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QWizard_page>

namespace Occ {


namespace Ui {
    class Welcome_page;
}

class Welcome_page : QWizard_page {

    /***********************************************************
    ***********************************************************/
    public Welcome_page (OwncloudWizard oc_wizard);
    ~Welcome_page () override;
    public int next_id () override;
    public void initialize_page () override;
    public void set_login_button_default ();


    /***********************************************************
    ***********************************************************/
    private void setup_ui ();
    private void customize_style ();
    private void style_slide_show ();
    private void setup_slide_show ();
    private void setup_login_button ();
    private void setup_create_account_button ();
    private void setup_host_your_own_server_label ();

    /***********************************************************
    ***********************************************************/
    private QScopedPointer<Ui.Welcome_page> this.ui;

    /***********************************************************
    ***********************************************************/
    private OwncloudWizard this.oc_wizard;
    private WizardCommon.Pages this.next_page = WizardCommon.Page_Server_setup;
};


    Welcome_page.Welcome_page (OwncloudWizard oc_wizard)
        : QWizard_page ()
        , this.ui (new Ui.Welcome_page)
        , this.oc_wizard (oc_wizard) {
        setup_ui ();
    }

    Welcome_page.~Welcome_page () = default;

    void Welcome_page.setup_ui () {
        this.ui.setup_ui (this);
        setup_slide_show ();
        setup_login_button ();
        setup_create_account_button ();
        setup_host_your_own_server_label ();
    }

    void Welcome_page.initialize_page () {
        customize_style ();
    }

    void Welcome_page.set_login_button_default () {
        this.ui.login_button.set_default (true);
        this.ui.login_button.set_focus ();
    }

    void Welcome_page.style_slide_show () {
        const var theme = Theme.instance ();
        const var background_color = palette ().window ().color ();

        const var wizard_nextcloud_icon_filename = theme.is_branded () ? Theme.hidpi_filename ("wizard-nextcloud.png", background_color)
                                                                    : Theme.hidpi_filename (":/client/theme/colored/wizard-nextcloud.png");
        const var wizard_files_icon_filename = theme.is_branded () ? Theme.hidpi_filename ("wizard-files.png", background_color)
                                                                : Theme.hidpi_filename (":/client/theme/colored/wizard-files.png");
        const var wizard_groupware_icon_filename = theme.is_branded () ? Theme.hidpi_filename ("wizard-groupware.png", background_color)
                                                                    : Theme.hidpi_filename (":/client/theme/colored/wizard-groupware.png");
        const var wizard_talk_icon_filename = theme.is_branded () ? Theme.hidpi_filename ("wizard-talk.png", background_color)
                                                               : Theme.hidpi_filename (":/client/theme/colored/wizard-talk.png");

        this.ui.slide_show.add_slide (wizard_nextcloud_icon_filename, _("Keep your data secure and under your control"));
        this.ui.slide_show.add_slide (wizard_files_icon_filename, _("Secure collaboration & file exchange"));
        this.ui.slide_show.add_slide (wizard_groupware_icon_filename, _("Easy-to-use web mail, calendaring & contacts"));
        this.ui.slide_show.add_slide (wizard_talk_icon_filename, _("Screensharing, online meetings & web conferences"));

        const var is_dark_background = Theme.is_dark_color (background_color);
        this.ui.slide_show_next_button.set_icon (theme.ui_theme_icon (string ("control-next.svg"), is_dark_background));
        this.ui.slide_show_previous_button.set_icon (theme.ui_theme_icon (string ("control-prev.svg"), is_dark_background));
    }

    void Welcome_page.setup_slide_show () {
        connect (this.ui.slide_show, &Slide_show.clicked, this.ui.slide_show, &Slide_show.on_stop_show);
        connect (this.ui.slide_show_next_button, &QPushButton.clicked, this.ui.slide_show, &Slide_show.on_next_slide);
        connect (this.ui.slide_show_previous_button, &QPushButton.clicked, this.ui.slide_show, &Slide_show.on_prev_slide);
    }

    void Welcome_page.setup_login_button () {
        const var app_name = Theme.instance ().app_name_gui ();

        this.ui.login_button.on_set_text (_("Log in to your %1").arg (app_name));
        connect (this.ui.login_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            this.next_page = WizardCommon.Page_Server_setup;
            this.oc_wizard.next ();
        });
    }

    void Welcome_page.setup_create_account_button () {
    #ifdef WITH_WEBENGINE
        connect (this.ui.create_account_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            this.oc_wizard.set_registration (true);
            this.next_page = WizardCommon.Page_Web_view;
            this.oc_wizard.next ();
        });
    #else // WITH_WEBENGINE
        connect (this.ui.create_account_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            this.oc_wizard.set_registration (true);
            Utility.open_browser (QStringLiteral ("https://nextcloud.com/register"));
        });
    #endif // WITH_WEBENGINE
    }

    void Welcome_page.setup_host_your_own_server_label () {
        this.ui.host_your_own_server_label.on_set_text (_("Host your own server"));
        this.ui.host_your_own_server_label.set_alignment (Qt.AlignCenter);
        this.ui.host_your_own_server_label.set_url (GLib.Uri ("https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation"));
    }

    int Welcome_page.next_id () {
        return this.next_page;
    }

    void Welcome_page.customize_style () {
        style_slide_show ();
    }
    }
    