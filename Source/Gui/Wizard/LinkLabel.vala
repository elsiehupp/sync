/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QLabel>
// #include <QUrl>

namespace Occ {

class LinkLabel : QLabel {
public:
    LinkLabel (Gtk.Widget *parent = nullptr);

    void setUrl (QUrl &url);

signals:
    void clicked ();

protected:
    void enterEvent (QEvent *event) override;

    void leaveEvent (QEvent *event) override;

    void mouseReleaseEvent (QMouseEvent *event) override;

private:
    void setFontUnderline (bool value);

    QUrl url;
};

}











namespace Occ {

    LinkLabel.LinkLabel (Gtk.Widget *parent) : QLabel (parent) {
    
    }
    
    void LinkLabel.setUrl (QUrl &url) {
        this.url = url;
    }
    
    void LinkLabel.enterEvent (QEvent * /*event*/) {
        setFontUnderline (true);
        setCursor (Qt.PointingHandCursor);
    }
    
    void LinkLabel.leaveEvent (QEvent * /*event*/) {
        setFontUnderline (false);
        setCursor (Qt.ArrowCursor);
    }
    
    void LinkLabel.mouseReleaseEvent (QMouseEvent * /*event*/) {
        if (url.isValid ()) {
            Utility.openBrowser (url);
        }
    
        emit clicked ();
    }
    
    void LinkLabel.setFontUnderline (bool value) {
        auto labelFont = font ();
        labelFont.setUnderline (value);
        setFont (labelFont);
    }
    
    }
    