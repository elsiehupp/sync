/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QResize_event>

// #include <QLabel>

namespace Occ {

/// Label that can elide its text
class Elided_label : QLabel {
public:
    Elided_label (Gtk.Widget *parent = nullptr);
    Elided_label (string &text, Gtk.Widget *parent = nullptr);

    void set_text (string &text);
    const string &text () { return _text; }

    void set_elide_mode (Qt.Text_elide_mode elide_mode);
    Qt.Text_elide_mode elide_mode () { return _elide_mode; }

protected:
    void resize_event (QResize_event *event) override;

private:
    string _text;
    Qt.Text_elide_mode _elide_mode = Qt.Elide_none;
};


    Elided_label.Elided_label (Gtk.Widget *parent)
        : QLabel (parent) {
    }
    
    Elided_label.Elided_label (string &text, Gtk.Widget *parent)
        : QLabel (text, parent)
        , _text (text) {
    }
    
    void Elided_label.set_text (string &text) {
        _text = text;
        QLabel.set_text (text);
        update ();
    }
    
    void Elided_label.set_elide_mode (Qt.Text_elide_mode elide_mode) {
        _elide_mode = elide_mode;
        update ();
    }
    
    void Elided_label.resize_event (QResize_event *event) {
        QLabel.resize_event (event);
    
        QFont_metrics fm = font_metrics ();
        string elided = fm.elided_text (_text, _elide_mode, event.size ().width ());
        QLabel.set_text (elided);
    }
    }
    