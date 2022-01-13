/***********************************************************
Copyright (C) 2016 by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QStyle>
// #include <QStyleOptionFrame>

// #include <QLineEdit>
// #include <QPaintEvent>
// #include <QPainter>

namespace Occ {

/***********************************************************
@brief A lineedit class with a pre-set postfix.

Useful e.g. for setting a fixed domain name.
***********************************************************/

class PostfixLineEdit : QLineEdit {
public:
    PostfixLineEdit (Gtk.Widget *parent);

    /***********************************************************
    @brief sets an optional postfix shown greyed out */
    /***********************************************************
     setPostfix (string &postfix);
    /***********************************************************
    @brief retrives the postfix */
    string postfix ();
    /** @brief retrieves combined text () and postfix () */
    string fullText ();

    /***********************************************************
    @brief sets text () from full text, discarding prefix () */
    void setFullText (string &text);

protected:
    void paintEvent (QPaintEvent *pe) override;

private:
    string _postfix;
};

    const int horizontalMargin (4);
    const int verticalMargin (4);
    
    PostfixLineEdit.PostfixLineEdit (Gtk.Widget *parent)
        : QLineEdit (parent) {
    }
    
    void PostfixLineEdit.setPostfix (string &postfix) {
        _postfix = postfix;
        QFontMetricsF fm (font ());
        QMargins tm = textMargins ();
        tm.setRight (tm.right () + qRound (fm.width (_postfix)) + verticalMargin);
        setTextMargins (tm);
    }
    
    string PostfixLineEdit.postfix () {
        return _postfix;
    }
    
    string PostfixLineEdit.fullText () {
        return text () + _postfix;
    }
    
    void PostfixLineEdit.setFullText (string &text) {
        string prefixString = text;
        if (prefixString.endsWith (postfix ())) {
            prefixString.chop (postfix ().length ());
        }
        setText (prefixString);
    }
    
    void PostfixLineEdit.paintEvent (QPaintEvent *pe) {
        QLineEdit.paintEvent (pe);
        QPainter p (this);
    
        //
        p.setPen (palette ().color (QPalette.Disabled, QPalette.Text));
        QFontMetricsF fm (font ());
        int start = rect ().right () - qRound (fm.width (_postfix));
        QStyleOptionFrame panel;
        initStyleOption (&panel);
        QRect r = style ().subElementRect (QStyle.SE_LineEditContents, &panel, this);
        r.setTop (r.top () + horizontalMargin - 1);
        QRect postfixRect (r);
    
        postfixRect.setLeft (start - verticalMargin);
        p.drawText (postfixRect, _postfix);
    }
    
    } // namespace Occ
    