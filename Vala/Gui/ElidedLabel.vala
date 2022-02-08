/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QResizeEvent>
//  #include <Gtk.Label>


namespace Occ {
namespace Ui {

/// Label that can elide its text
class ElidedLabel : Gtk.Label {

    /***********************************************************
    ***********************************************************/
    public ElidedLabel (Gtk.Widget parent = null);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public const string text () {
        return this.text;
    }


    /***********************************************************
    ***********************************************************/
    public void elide_mode (Qt.TextElideMode elide_mode);

    /***********************************************************
    ***********************************************************/
    public Qt.TextElideMode elide_mode () {
        return this.elide_mode;
    }


    protected void resize_event (QResizeEvent event) override;


    /***********************************************************
    ***********************************************************/
    private string this.text;
    private Qt.TextElideMode this.elide_mode = Qt.ElideNone;
}


    ElidedLabel.ElidedLabel (Gtk.Widget parent)
        : Gtk.Label (parent) {
    }

    ElidedLabel.ElidedLabel (string text, Gtk.Widget parent)
        : Gtk.Label (text, parent)
        this.text (text) {
    }

    void ElidedLabel.on_signal_text (string text) {
        this.text = text;
        Gtk.Label.on_signal_text (text);
        update ();
    }

    void ElidedLabel.elide_mode (Qt.TextElideMode elide_mode) {
        this.elide_mode = elide_mode;
        update ();
    }

    void ElidedLabel.resize_event (QResizeEvent event) {
        Gtk.Label.resize_event (event);

        QFontMetrics fm = font_metrics ();
        string elided = fm.elided_text (this.text, this.elide_mode, event.size ().width ());
        Gtk.Label.on_signal_text (elided);
    }
    }
    