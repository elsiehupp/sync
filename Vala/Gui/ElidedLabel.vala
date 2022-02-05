/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QResizeEvent>
//  #include <QLabel>

namespace Occ {

/// Label that can elide its text
class ElidedLabel : QLabel {

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
        : QLabel (parent) {
    }

    ElidedLabel.ElidedLabel (string text, Gtk.Widget parent)
        : QLabel (text, parent)
        this.text (text) {
    }

    void ElidedLabel.on_text (string text) {
        this.text = text;
        QLabel.on_text (text);
        update ();
    }

    void ElidedLabel.elide_mode (Qt.TextElideMode elide_mode) {
        this.elide_mode = elide_mode;
        update ();
    }

    void ElidedLabel.resize_event (QResizeEvent event) {
        QLabel.resize_event (event);

        QFontMetrics fm = font_metrics ();
        string elided = fm.elided_text (this.text, this.elide_mode, event.size ().width ());
        QLabel.on_text (elided);
    }
    }
    