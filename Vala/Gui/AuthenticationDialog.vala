/***********************************************************
@author 2014 by Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.LineEdit>
//  #include <GLib.VBoxLayout>
//  #include <GLib.FormLayout>
//  #include <GLib.DialogButtonBox>
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

/***********************************************************
@brief Authenticate a user for a specific credential given
their credentials
@ingroup gui
***********************************************************/
public class AuthenticationDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private GLib.LineEdit user;
    private GLib.LineEdit password;

    /***********************************************************
    ***********************************************************/
    public AuthenticationDialog (string realm, string domain, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.user = new GLib.LineEdit ();
        this.password = new GLib.LineEdit ();
        this.window_title (_("Authentication Required"));
        var vertical_box_layout = new GLib.VBoxLayout (this);
        var label = new Gtk.Label (_("Enter username and password for \"%1\" at %2.").printf (realm, domain));
        label.text_format (Qt.UpdateStatusStringFormat.PLAIN_TEXT);
        vertical_box_layout.add_widget (label);

        var form = new GLib.FormLayout ();
        form.add_row (_("&User:"), this.user);
        form.add_row (_("&Password:"), this.password);
        vertical_box_layout.add_layout (form);
        this.password.echo_mode (GLib.LineEdit.Password);

        var dialog_button_box = new GLib.DialogButtonBox (GLib.DialogButtonBox.Ok | GLib.DialogButtonBox.Cancel, Qt.Horizontal);
        dialog_button_box.accepted.connect (
            this.accept
        );
        dialog_button_box.rejected.connect (
            this.reject
        );
        vertical_box_layout.add_widget (dialog_button_box);
    }


    /***********************************************************
    ***********************************************************/
    public string user_text () {
        return this.user.text ();
    }


    /***********************************************************
    ***********************************************************/
    public string password_text () {
        return this.password.text ();
    }

} // class AuthenticationDialog

} // namespace Ui
} // namespace Occ
