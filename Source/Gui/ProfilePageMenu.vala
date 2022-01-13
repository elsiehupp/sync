#pragma once

// #include <QBoxLayout>
// #include <QLabel>
// #include <account.h>
// #include <QMenu>

// #include <cstddef>

namespace Occ {

class ProfilePageMenu : Gtk.Widget {
public:
    ProfilePageMenu (AccountPtr account, string &shareWithUserId, Gtk.Widget *parent = nullptr);
    ~ProfilePageMenu () override;

    void exec (QPoint &globalPosition);

private:
    void onHovercardFetched ();
    void onIconLoaded (std.size_t &hovercardActionIndex);

    OcsProfileConnector _profileConnector;
    QMenu _menu;
};


    ProfilePageMenu.ProfilePageMenu (AccountPtr account, string &shareWithUserId, Gtk.Widget *parent)
        : Gtk.Widget (parent)
        , _profileConnector (account) {
        connect (&_profileConnector, &OcsProfileConnector.hovercardFetched, this, &ProfilePageMenu.onHovercardFetched);
        connect (&_profileConnector, &OcsProfileConnector.iconLoaded, this, &ProfilePageMenu.onIconLoaded);
        _profileConnector.fetchHovercard (shareWithUserId);
    }
    
    ProfilePageMenu.~ProfilePageMenu () = default;
    
    void ProfilePageMenu.exec (QPoint &globalPosition) {
        _menu.exec (globalPosition);
    }
    
    void ProfilePageMenu.onHovercardFetched () {
        _menu.clear ();
    
        const auto hovercardActions = _profileConnector.hovercard ()._actions;
        for (auto &hovercardAction : hovercardActions) {
            const auto action = _menu.addAction (hovercardAction._icon, hovercardAction._title);
            const auto link = hovercardAction._link;
            connect (action, &QAction.triggered, action, [link] (bool) { Utility.openBrowser (link); });
        }
    }
    
    void ProfilePageMenu.onIconLoaded (std.size_t &hovercardActionIndex) {
        const auto hovercardActions = _profileConnector.hovercard ()._actions;
        const auto menuActions = _menu.actions ();
        if (hovercardActionIndex >= hovercardActions.size ()
            || hovercardActionIndex >= static_cast<std.size_t> (menuActions.size ())) {
            return;
        }
        const auto menuAction = menuActions[static_cast<int> (hovercardActionIndex)];
        menuAction.setIcon (hovercardActions[hovercardActionIndex]._icon);
    }
    }
    