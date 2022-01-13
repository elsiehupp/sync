/*
Copyright (C) by Christian Kamm <mail@ckamm.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QResizeEvent>

namespace Occ {

ElidedLabel.ElidedLabel (QWidget *parent)
    : QLabel (parent) {
}

ElidedLabel.ElidedLabel (QString &text, QWidget *parent)
    : QLabel (text, parent)
    , _text (text) {
}

void ElidedLabel.setText (QString &text) {
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
    QString elided = fm.elidedText (_text, _elideMode, event.size ().width ());
    QLabel.setText (elided);
}
}
