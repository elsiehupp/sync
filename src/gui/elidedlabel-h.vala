/*
 * Copyright (C) by Christian Kamm <mail@ckamm.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QLabel>

namespace OCC {

/// Label that can elide its text
class ElidedLabel : public QLabel {
public:
    explicit ElidedLabel (QWidget *parent = nullptr);
    explicit ElidedLabel (QString &text, QWidget *parent = nullptr);

    void setText (QString &text);
    const QString &text () const { return _text; }

    void setElideMode (Qt::TextElideMode elideMode);
    Qt::TextElideMode elideMode () const { return _elideMode; }

protected:
    void resizeEvent (QResizeEvent *event) override;

private:
    QString _text;
    Qt::TextElideMode _elideMode = Qt::ElideNone;
};
}

#endif
