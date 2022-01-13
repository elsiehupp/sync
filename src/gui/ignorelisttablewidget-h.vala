#pragma once

// #include <QWidget>

class QAbstractButton;

namespace OCC {

namespace Ui {
    class IgnoreListTableWidget;
}

class IgnoreListTableWidget : public QWidget {

public:
    IgnoreListTableWidget(QWidget *parent = nullptr);
    ~IgnoreListTableWidget() override;

    void readIgnoreFile(QString &file, bool readOnly = false);
    int addPattern(QString &pattern, bool deletable, bool readOnly);

public slots:
    void slotRemoveAllItems();
    void slotWriteIgnoreFile(QString & file);

private slots:
    void slotItemSelectionChanged();
    void slotRemoveCurrentItem();
    void slotAddPattern();

private:
    void setupTableReadOnlyItems();
    QString readOnlyTooltip;
    Ui::IgnoreListTableWidget *ui;
};
} // namespace OCC
