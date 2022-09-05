/***********************************************************
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The LegalNotice class
@ingroup gui
***********************************************************/
public class LegalNotice { //: Gtk.Dialog {

    //  /***********************************************************
    //  ***********************************************************/
    //  private LegalNotice instance;

    //  /***********************************************************
    //  ***********************************************************/
    //  public LegalNotice () {
    //      base ();
    //      this.instance = new LegalNotice ();
    //      this.instance.up_ui (this);

    //      this.instance.close_button.clicked.connect (
    //          this.accept
    //      );

    //      customize_style ();
    //  }

    //  /***********************************************************
    //  ***********************************************************/
    //  public LegalNotice.with_parent (Gtk.Dialog parent) {
    //      base (parent);
    //      this.instance = new LegalNotice ();
    //      this.instance.up_ui (this);

    //      this.instance.close_button.clicked.connect (
    //          this.accept
    //      );

    //      customize_style ();
    //  }


    //  override ~LegalNotice () {
    //      //  delete this.instance;
    //  }



    //  /***********************************************************
    //  ***********************************************************/
    //  protected override void change_event (Gdk.Event e) {
    //      switch (e.type) {
    //      case Gdk.Event.StyleChange:
    //      case Gdk.Event.PaletteChange:
    //      case Gdk.Event.ThemeChange:
    //          customize_style ();
    //          break;
    //      default:
    //          break;
    //      }

    //      Gtk.Dialog.change_event (e);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void customize_style () {
    //      string notice = _("<p>Copyright 2017-2021 Nextcloud Gmb_h<br />"
    //                      + "Copyright 2012-2021 own_cloud Gmb_h</p>");

    //      notice += _("<p>Licensed under the GNU General Public License (GPL) Version 2.0 or any later version.</p>");

    //      notice += "<p>&nbsp;</p>";
    //      notice += LibSync.Theme.about_details;

    //      LibSync.Theme.replace_link_color_string_background_aware (notice);

    //      this.instance.notice.text_interaction_flags (GLib.Text_selectable_by_mouse | GLib.TextBrowserInteraction);
    //      this.instance.notice.on_signal_text (notice);
    //      this.instance.notice.word_wrap (true);
    //      this.instance.notice.open_external_links (true);
    //  }

} // class LegalNotice

} // namespace Ui
} // namespace Occ
