/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Legal_notice class
@ingroup gui
***********************************************************/
class Legal_notice : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public Legal_notice (Gtk.Dialog parent = null);
    ~Legal_notice () override;


    protected void change_event (QEvent *) override;


    /***********************************************************
    ***********************************************************/
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private Ui.Legal_notice this.ui;
}

    Legal_notice.Legal_notice (Gtk.Dialog parent)
        : Gtk.Dialog (parent)
        this.ui (new Ui.Legal_notice) {
        this.ui.up_ui (this);

        connect (this.ui.close_button, &QPushButton.clicked, this, &Legal_notice.accept);

        customize_style ();
    }

    Legal_notice.~Legal_notice () {
        delete this.ui;
    }

    void Legal_notice.change_event (QEvent e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customize_style ();
            break;
        default:
            break;
        }

        Gtk.Dialog.change_event (e);
    }

    void Legal_notice.customize_style () {
        string notice = _("<p>Copyright 2017-2021 Nextcloud Gmb_h<br />"
                            "Copyright 2012-2021 own_cloud Gmb_h</p>");

        notice += _("<p>Licensed under the GNU General Public License (GPL) Version 2.0 or any later version.</p>");

        notice += "<p>&nbsp;</p>";
        notice += Theme.instance ().about_details ();

        Theme.replace_link_color_string_background_aware (notice);

        this.ui.notice.text_interaction_flags (Qt.Text_selectable_by_mouse | Qt.Text_browser_interaction);
        this.ui.notice.on_text (notice);
        this.ui.notice.word_wrap (true);
        this.ui.notice.open_external_links (true);
    }

    } // namespace Occ
    