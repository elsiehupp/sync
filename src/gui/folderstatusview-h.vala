/*
 * Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>
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


// #include <QTreeView>

namespace OCC {

/**
 * @brief The FolderStatusView class
 * @ingroup gui
 */
class FolderStatusView : public QTreeView
{

public:
    explicit FolderStatusView(QWidget *parent = nullptr);

    QModelIndex indexAt(const QPoint &point) const override;
    QRect visualRect(const QModelIndex &index) const override;
};

} // namespace OCC

#endif // FOLDERSTATUSVIEW_H
