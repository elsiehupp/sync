/*
Copyright (C) 2018 by J-P Nurmi <jpnurmi@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QTreeView>

namespace Occ {

/**
@brief The FolderStatusView class
@ingroup gui
*/
class FolderStatusView : QTreeView {

public:
    FolderStatusView (QWidget *parent = nullptr);

    QModelIndex indexAt (QPoint &point) const override;
    QRect visualRect (QModelIndex &index) const override;
};

} // namespace Occ
