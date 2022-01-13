/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QResizeEvent>

// #include <QLabel>

namespace Occ {

/// Label that can elide its text
class ElidedLabel : QLabel {
public:
    ElidedLabel (Gtk.Widget *parent = nullptr);
    ElidedLabel (string &text, Gtk.Widget *parent = nullptr);

    void setText (string &text);
    const string &text () { return _text; }

    void setElideMode (Qt.TextElideMode elideMode);
    Qt.TextElideMode elideMode () { return _elideMode; }

protected:
    void resizeEvent (QResizeEvent *event) override;

private:
    string _text;
    Qt.TextElideMode _elideMode = Qt.ElideNone;
};


    ElidedLabel.ElidedLabel (Gtk.Widget *parent)
        : QLabel (parent) {
    }
    
    ElidedLabel.ElidedLabel (string &text, Gtk.Widget *parent)
        : QLabel (text, parent)
        , _text (text) {
    }
    
    void ElidedLabel.setText (string &text) {
        _text = text;
        QLabel.setText (text);
        update ();
    }
    
    void ElidedLabel.setElideMode (Qt.TextElideMode elideMode) {
        _elideMode = elideMode;
        update ();
    }
    
    void ElidedLabel.resizeEvent (QResizeEvent *event) {
        QLabel.resizeEvent (event);
    
        QFontMetrics fm = fontMetrics ();
        string elided = fm.elidedText (_text, _elideMode, event.size ().width ());
        QLabel.setText (elided);
    }
    }
    