/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QLabel>
// #include <QUrl>

namespace Occ {

class Link_label : QLabel {

    public Link_label (Gtk.Widget *parent = nullptr);

    public void set_url (QUrl url);

signals:
    void clicked ();


    protected void enter_event (QEvent *event) override;

    protected void leave_event (QEvent *event) override;

    protected void mouse_release_event (QMouse_event *event) override;


    private void set_font_underline (bool value);

    private QUrl url;
};

    Link_label.Link_label (Gtk.Widget *parent) : QLabel (parent) {

    }

    void Link_label.set_url (QUrl url) {
        this.url = url;
    }

    void Link_label.enter_event (QEvent * /*event*/) {
        set_font_underline (true);
        set_cursor (Qt.PointingHandCursor);
    }

    void Link_label.leave_event (QEvent * /*event*/) {
        set_font_underline (false);
        set_cursor (Qt.ArrowCursor);
    }

    void Link_label.mouse_release_event (QMouse_event * /*event*/) {
        if (url.is_valid ()) {
            Utility.open_browser (url);
        }

        emit clicked ();
    }

    void Link_label.set_font_underline (bool value) {
        auto label_font = font ();
        label_font.set_underline (value);
        set_font (label_font);
    }

    }
    