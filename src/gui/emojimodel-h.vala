/*
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #pragma once

// #include <GLib.Object>
// #include <QSettings>
// #include <GLib.Object>
// #include <QQmlEngine>
// #include <QVariant>
// #include <QVector>
// #include <QAbstractItemModel>

namespace Occ {

struct Emoji {
    Emoji (QString u, QString s, bool isCustom = false)
        : unicode (std.move (std.move (u)))
        , shortname (std.move (std.move (s)))
        , isCustom (isCustom) {
    }
    Emoji () = default;

    friend QDataStream &operator<< (QDataStream &arch, Emoji &object) {
        arch << object.unicode;
        arch << object.shortname;
        return arch;
    }

    friend QDataStream &operator>> (QDataStream &arch, Emoji &object) {
        arch >> object.unicode;
        arch >> object.shortname;
        object.isCustom = object.unicode.startsWith ("image://");
        return arch;
    }

    QString unicode;
    QString shortname;
    bool isCustom = false;

    Q_GADGET
    Q_PROPERTY (QString unicode MEMBER unicode)
    Q_PROPERTY (QString shortname MEMBER shortname)
    Q_PROPERTY (bool isCustom MEMBER isCustom)
};

class EmojiCategoriesModel : QAbstractListModel {
public:
    QVariant data (QModelIndex &index, int role) const override;
    int rowCount (QModelIndex &parent = QModelIndex ()) const override;
    QHash<int, QByteArray> roleNames () const override;

private:
    enum Roles {
        EmojiRole = 0,
        LabelRole
    };

    struct Category {
        QString emoji;
        QString label;
    };

    static const std.vector<Category> categories;
};

class EmojiModel : GLib.Object {

    Q_PROPERTY (QVariantList model READ model NOTIFY modelChanged)
    Q_PROPERTY (QAbstractListModel *emojiCategoriesModel READ emojiCategoriesModel CONSTANT)

    Q_PROPERTY (QVariantList history READ history NOTIFY historyChanged)

    Q_PROPERTY (QVariantList people MEMBER people CONSTANT)
    Q_PROPERTY (QVariantList nature MEMBER nature CONSTANT)
    Q_PROPERTY (QVariantList food MEMBER food CONSTANT)
    Q_PROPERTY (QVariantList activity MEMBER activity CONSTANT)
    Q_PROPERTY (QVariantList travel MEMBER travel CONSTANT)
    Q_PROPERTY (QVariantList objects MEMBER objects CONSTANT)
    Q_PROPERTY (QVariantList symbols MEMBER symbols CONSTANT)
    Q_PROPERTY (QVariantList flags MEMBER flags CONSTANT)

public:
    EmojiModel (GLib.Object *parent = nullptr)
        : GLib.Object (parent) {
    }

    Q_INVOKABLE QVariantList history ();
    Q_INVOKABLE void setCategory (QString &category);
    Q_INVOKABLE void emojiUsed (QVariant &modelData);

    QVariantList model ();
    QAbstractListModel *emojiCategoriesModel ();

signals:
    void historyChanged ();
    void modelChanged ();

private:
    static const QVariantList people;
    static const QVariantList nature;
    static const QVariantList food;
    static const QVariantList activity;
    static const QVariantList travel;
    static const QVariantList objects;
    static const QVariantList symbols;
    static const QVariantList flags;

    QSettings _settings;
    QString _category = "history";

    EmojiCategoriesModel _emojiCategoriesModel;
};

}

Q_DECLARE_METATYPE (Occ.Emoji)
