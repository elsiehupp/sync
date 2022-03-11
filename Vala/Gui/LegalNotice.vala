/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The LegalNotice class
@ingroup gui
***********************************************************/
class LegalNotice : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private Ui.LegalNotice ui;

    /***********************************************************
    ***********************************************************/
    public LegalNotice (Gtk.Dialog parent = null) {
        base (parent);
        this.ui = new Ui.LegalNotice ();
        this.ui.up_ui (this);

        connect (this.ui.close_button, &QPushButton.clicked, this, &LegalNotice.accept);

        customize_style ();
    }


    override ~LegalNotice () {
        delete this.ui;
    }



    /***********************************************************
    ***********************************************************/
    protected override void change_event (QEvent e) {
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


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        string notice = _("<p>Copyright 2017-2021 Nextcloud Gmb_h<br />"
                        + "Copyright 2012-2021 own_cloud Gmb_h</p>");

        notice += _("<p>Licensed under the GNU General Public License (GPL) Version 2.0 or any later version.</p>");

        notice += "<p>&nbsp;</p>";
        notice += Theme.instance ().about_details ();

        Theme.replace_link_color_string_background_aware (notice);

        this.ui.notice.text_interaction_flags (Qt.Text_selectable_by_mouse | Qt.TextBrowserInteraction);
        this.ui.notice.on_signal_text (notice);
        this.ui.notice.word_wrap (true);
        this.ui.notice.open_external_links (true);
    }

} // class LegalNotice

} // namespace Ui
} // namespace Occ
