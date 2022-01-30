/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QResizeEvent>

// #include <QLabel>

namespace Occ {

/// Label that can elide its text
class ElidedLabel : QLabel {

    /***********************************************************
    ***********************************************************/
    public ElidedLabel (Gtk.Widget parent = nullptr);

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
        return _text;
    }


    /***********************************************************
    ***********************************************************/
    public void set_elide_mode (Qt.TextElideMode elide_mode);

    /***********************************************************
    ***********************************************************/
    public 
    public Qt.TextElideMode elide_mode () {
        return _elide_mode;
    }


    protected void resize_event (QResizeEvent event) override;


    /***********************************************************
    ***********************************************************/
    private string _text;
    private Qt.TextElideMode _elide_mode = Qt.ElideNone;
};


    ElidedLabel.ElidedLabel (Gtk.Widget parent)
        : QLabel (parent) {
    }

    ElidedLabel.ElidedLabel (string text, Gtk.Widget parent)
        : QLabel (text, parent)
        , _text (text) {
    }

    void ElidedLabel.on_set_text (string text) {
        _text = text;
        QLabel.on_set_text (text);
        update ();
    }

    void ElidedLabel.set_elide_mode (Qt.TextElideMode elide_mode) {
        _elide_mode = elide_mode;
        update ();
    }

    void ElidedLabel.resize_event (QResizeEvent event) {
        QLabel.resize_event (event);

        QFontMetrics fm = font_metrics ();
        string elided = fm.elided_text (_text, _elide_mode, event.size ().width ());
        QLabel.on_set_text (elided);
    }
    }
    