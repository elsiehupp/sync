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

    public Welcome_page (OwncloudWizard *oc_wizard);
    ~Welcome_page () override;
    public int next_id () override;
    public void initialize_page () override;
    public void set_login_button_default ();


    private void setup_ui ();
    private void customize_style ();
    private void style_slide_show ();
    private void setup_slide_show ();
    private void setup_login_button ();
    private void setup_create_account_button ();
    private void setup_host_your_own_server_label ();

    private QScopedPointer<Ui.Welcome_page> _ui;

    private OwncloudWizard _oc_wizard;
    private WizardCommon.Pages _next_page = WizardCommon.Page_Server_setup;
};


    Welcome_page.Welcome_page (OwncloudWizard *oc_wizard)
        : QWizard_page ()
        , _ui (new Ui.Welcome_page)
        , _oc_wizard (oc_wizard) {
        setup_ui ();
    }

    Welcome_page.~Welcome_page () = default;

    void Welcome_page.setup_ui () {
        _ui.setup_ui (this);
        setup_slide_show ();
        setup_login_button ();
        setup_create_account_button ();
        setup_host_your_own_server_label ();
    }

    void Welcome_page.initialize_page () {
        customize_style ();
    }

    void Welcome_page.set_login_button_default () {
        _ui.login_button.set_default (true);
        _ui.login_button.set_focus ();
    }

    void Welcome_page.style_slide_show () {
        const auto theme = Theme.instance ();
        const auto background_color = palette ().window ().color ();

        const auto wizard_nextcloud_icon_file_name = theme.is_branded () ? Theme.hidpi_file_name ("wizard-nextcloud.png", background_color)
                                                                    : Theme.hidpi_file_name (":/client/theme/colored/wizard-nextcloud.png");
        const auto wizard_files_icon_file_name = theme.is_branded () ? Theme.hidpi_file_name ("wizard-files.png", background_color)
                                                                : Theme.hidpi_file_name (":/client/theme/colored/wizard-files.png");
        const auto wizard_groupware_icon_file_name = theme.is_branded () ? Theme.hidpi_file_name ("wizard-groupware.png", background_color)
                                                                    : Theme.hidpi_file_name (":/client/theme/colored/wizard-groupware.png");
        const auto wizard_talk_icon_file_name = theme.is_branded () ? Theme.hidpi_file_name ("wizard-talk.png", background_color)
                                                               : Theme.hidpi_file_name (":/client/theme/colored/wizard-talk.png");

        _ui.slide_show.add_slide (wizard_nextcloud_icon_file_name, tr ("Keep your data secure and under your control"));
        _ui.slide_show.add_slide (wizard_files_icon_file_name, tr ("Secure collaboration & file exchange"));
        _ui.slide_show.add_slide (wizard_groupware_icon_file_name, tr ("Easy-to-use web mail, calendaring & contacts"));
        _ui.slide_show.add_slide (wizard_talk_icon_file_name, tr ("Screensharing, online meetings & web conferences"));

        const auto is_dark_background = Theme.is_dark_color (background_color);
        _ui.slide_show_next_button.set_icon (theme.ui_theme_icon (string ("control-next.svg"), is_dark_background));
        _ui.slide_show_previous_button.set_icon (theme.ui_theme_icon (string ("control-prev.svg"), is_dark_background));
    }

    void Welcome_page.setup_slide_show () {
        connect (_ui.slide_show, &Slide_show.clicked, _ui.slide_show, &Slide_show.on_stop_show);
        connect (_ui.slide_show_next_button, &QPushButton.clicked, _ui.slide_show, &Slide_show.on_next_slide);
        connect (_ui.slide_show_previous_button, &QPushButton.clicked, _ui.slide_show, &Slide_show.on_prev_slide);
    }

    void Welcome_page.setup_login_button () {
        const auto app_name = Theme.instance ().app_name_gui ();

        _ui.login_button.on_set_text (tr ("Log in to your %1").arg (app_name));
        connect (_ui.login_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _next_page = WizardCommon.Page_Server_setup;
            _oc_wizard.next ();
        });
    }

    void Welcome_page.setup_create_account_button () {
    #ifdef WITH_WEBENGINE
        connect (_ui.create_account_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _oc_wizard.set_registration (true);
            _next_page = WizardCommon.Page_Web_view;
            _oc_wizard.next ();
        });
    #else // WITH_WEBENGINE
        connect (_ui.create_account_button, &QPushButton.clicked, this, [this] (bool /*checked*/) {
            _oc_wizard.set_registration (true);
            Utility.open_browser (QStringLiteral ("https://nextcloud.com/register"));
        });
    #endif // WITH_WEBENGINE
    }

    void Welcome_page.setup_host_your_own_server_label () {
        _ui.host_your_own_server_label.on_set_text (tr ("Host your own server"));
        _ui.host_your_own_server_label.set_alignment (Qt.AlignCenter);
        _ui.host_your_own_server_label.set_url (QUrl ("https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation"));
    }

    int Welcome_page.next_id () {
        return _next_page;
    }

    void Welcome_page.customize_style () {
        style_slide_show ();
    }
    }
    