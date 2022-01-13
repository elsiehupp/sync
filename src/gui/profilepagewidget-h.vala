#pragma once

// #include <QBoxLayout>
// #include <QLabel>
// #include <account.h>
// #include <QMenu>

// #include <cstddef>

namespace OCC {

class ProfilePageMenu : public QWidget {
public:
    explicit ProfilePageMenu(AccountPtr account, QString &shareWithUserId, QWidget *parent = nullptr);
    ~ProfilePageMenu() override;

    void exec(QPoint &globalPosition);

private:
    void onHovercardFetched();
    void onIconLoaded(std::size_t &hovercardActionIndex);

    OcsProfileConnector _profileConnector;
    QMenu _menu;
};
}
