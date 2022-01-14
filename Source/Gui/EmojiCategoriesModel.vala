/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtGlobal>
// #include <memory>

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
    Emoji (string u, string s, bool is_custom = false)
        : unicode (std.move (std.move (u)))
        , shortname (std.move (std.move (s)))
        , is_custom (is_custom) {
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
        object.is_custom = object.unicode.starts_with ("image://");
        return arch;
    }

    string unicode;
    string shortname;
    bool is_custom = false;

    Q_GADGET
    Q_PROPERTY (string unicode MEMBER unicode)
    Q_PROPERTY (string shortname MEMBER shortname)
    Q_PROPERTY (bool is_custom MEMBER is_custom)
};

class EmojiCategoriesModel : QAbstractListModel {

    public QVariant data (QModelIndex &index, int role) const override;
    public int row_count (QModelIndex &parent = QModelIndex ()) const override;
    public QHash<int, QByteArray> role_names () const override;

private:
    enum Roles {
        EmojiRole = 0,
        LabelRole
    };

    struct Category {
        string emoji;
        string label;
    };

    static const std.vector<Category> categories;
};

class EmojiModel : GLib.Object {

    Q_PROPERTY (QVariantList model READ model NOTIFY model_changed)
    Q_PROPERTY (QAbstractListModel *emoji_categories_model READ emoji_categories_model CONSTANT)

    Q_PROPERTY (QVariantList history READ history NOTIFY history_changed)

    Q_PROPERTY (QVariantList people MEMBER people CONSTANT)
    Q_PROPERTY (QVariantList nature MEMBER nature CONSTANT)
    Q_PROPERTY (QVariantList food MEMBER food CONSTANT)
    Q_PROPERTY (QVariantList activity MEMBER activity CONSTANT)
    Q_PROPERTY (QVariantList travel MEMBER travel CONSTANT)
    Q_PROPERTY (QVariantList objects MEMBER objects CONSTANT)
    Q_PROPERTY (QVariantList symbols MEMBER symbols CONSTANT)
    Q_PROPERTY (QVariantList flags MEMBER flags CONSTANT)

    public EmojiModel (GLib.Object *parent = nullptr)
        : GLib.Object (parent) {
    }

    public Q_INVOKABLE QVariantList history ();
    public Q_INVOKABLE void set_category (string &category);
    public Q_INVOKABLE void emoji_used (QVariant &model_data);

    public QVariantList model ();
    public QAbstractListModel *emoji_categories_model ();

signals:
    void history_changed ();
    void model_changed ();

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
    string _category = "history";

    EmojiCategoriesModel _emoji_categories_model;
};


    QVariant EmojiCategoriesModel.data (QModelIndex &index, int role) {
        if (!index.is_valid ()) {
            return {};
        }

        switch (role) {
        case Roles.EmojiRole:
            return categories[index.row ()].emoji;

        case Roles.LabelRole:
            return categories[index.row ()].label;
        }

        return {};
    }

    int EmojiCategoriesModel.row_count (QModelIndex &parent) {
        Q_UNUSED (parent);
        return static_cast<int> (categories.size ());
    }

    QHash<int, QByteArray> EmojiCategoriesModel.role_names () {
        QHash<int, QByteArray> roles;
        roles[Roles.EmojiRole] = "emoji";
        roles[Roles.LabelRole] = "label";
        return roles;
    }

    const std.vector<EmojiCategoriesModel.Category> EmojiCategoriesModel.categories = {
        {
            "⌛️",
            "history"
        },
        {
            "😏",
            "people"
        },
        {
            "🌲",
            "nature"
        },
        {
            "🍛",
            "food"
        },
        {
            "🚁",
            "activity"
        },
        {
            "🚅",
            "travel"
        },
        {
            "💡",
            "objects"
        },
        {
            "🔣",
            "symbols"
        },
        {
            "🏁",
            "flags"
        },
    };

    QVariantList EmojiModel.history () {
        return _settings.value ("Editor/emojis", QVariantList ()).to_list ();
    }

    void EmojiModel.set_category (string &category) {
        if (_category == category) {
            return;
        }
        _category = category;
        emit model_changed ();
    }

    QAbstractListModel *EmojiModel.emoji_categories_model () {
        return &_emoji_categories_model;
    }

    QVariantList EmojiModel.model () {
        if (_category == "history") {
            return history ();
        } else if (_category == "people") {
            return people;
        } else if (_category == "nature") {
            return nature;
        } else if (_category == "food") {
            return food;
        } else if (_category == "activity") {
            return activity;
        } else if (_category == "travel") {
            return travel;
        } else if (_category == "objects") {
            return objects;
        } else if (_category == "symbols") {
            return symbols;
        } else if (_category == "flags") {
            return flags;
        }
        return history ();
    }

    void EmojiModel.emoji_used (QVariant &model_data) {
        auto history_emojis = history ();

        auto history_emojis_iter = history_emojis.begin ();
        while (history_emojis_iter != history_emojis.end ()) {
            if ( (*history_emojis_iter).value<Emoji> ().unicode == model_data.value<Emoji> ().unicode) {
                history_emojis_iter = history_emojis.erase (history_emojis_iter);
            } else {
                history_emojis_iter++;
            }
        }

        history_emojis.push_front (model_data);
        _settings.set_value ("Editor/emojis", history_emojis);

        emit history_changed ();
    }

    const QVariantList EmojiModel.people = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x80"), ":grinning:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x81"), ":grin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x82"), ":joy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa3"), ":rofl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x83"), ":smiley:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x84"), ":smile:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x85"), ":sweat_smile:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x86"), ":laughing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x89"), ":wink:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8a"), ":blush:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8b"), ":yum:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8e"), ":sunglasses:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8d"), ":heart_eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x98"), ":kissing_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x97"), ":kissing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x99"), ":kissing_smiling_eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9a"), ":kissing_closed_eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xba"), ":relaxed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x82"), ":slight_smile:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x97"), ":hugging:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x94"), ":thinking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x90"), ":neutral_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x91"), ":expressionless:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb6"), ":no_mouth:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x84"), ":rolling_eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8f"), ":smirk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa3"), ":persevere:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa5"), ":disappointed_relieved:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xae"), ":open_mouth:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x90"), ":zipper_mouth:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xaf"), ":hushed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xaa"), ":sleepy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xab"), ":tired_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb4"), ":sleeping:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x8c"), ":relieved:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x93"), ":nerd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9b"), ":stuck_out_tongue:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9c"), ":stuck_out_tongue_winking_eye:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9d"), ":stuck_out_tongue_closed_eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa4"), ":drooling_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x92"), ":unamused:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x93"), ":sweat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x94"), ":pensive:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x95"), ":confused:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x83"), ":upside_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x91"), ":money_mouth:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb2"), ":astonished:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xb9"), ":frowning2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x81"), ":slight_frown:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x96"), ":confounded:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9e"), ":disappointed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x9f"), ":worried:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa4"), ":triumph:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa2"), ":cry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xad"), ":sob:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa6"), ":frowning:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa7"), ":anguished:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa8"), ":fearful:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa9"), ":weary:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xac"), ":grimacing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb0"), ":cold_sweat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb1"), ":scream:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb3"), ":flushed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb5"), ":dizzy_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa1"), ":rage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xa0"), ":angry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x87"), ":innocent:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa0"), ":cowboy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa1"), ":clown:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa5"), ":lying_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb7"), ":mask:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x92"), ":thermometer_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x95"), ":head_bandage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa2"), ":nauseated_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa7"), ":sneezing_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\x88"), ":smiling_imp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xbf"), ":imp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb9"), ":japanese_ogre:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xba"), ":japanese_goblin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x80"), ":skull:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xbb"), ":ghost:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xbd"), ":alien:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x96"), ":robot:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa9"), ":poop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xba"), ":smiley_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb8"), ":smile_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xb9"), ":joy_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xbb"), ":heart_eyes_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xbc"), ":smirk_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xbd"), ":kissing_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x80"), ":scream_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xbf"), ":crying_cat_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x98\xbe"), ":pouting_cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa6"), ":boy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa7"), ":girl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa8"), ":man:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa9"), ":woman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb4"), ":older_man:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb5"), ":older_woman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb6"), ":baby:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xbc"), ":angel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xae"), ":cop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb5"), ":spy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x82"), ":guardsman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb7"), ":construction_worker:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb3"), ":man_with_turban:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb1"), ":person_with_blond_hair:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x85"), ":santa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb6"), ":mrs_claus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb8"), ":princess:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb4"), ":prince:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb0"), ":bride_with_veil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb5"), ":man_in_tuxedo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb0"), ":pregnant_woman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xb2"), ":man_with_gua_pi_mao:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8d"), ":person_frowning:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8e"), ":person_with_pouting_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x85"), ":no_good:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x86"), ":ok_woman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x81"), ":information_desk_person:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8b"), ":raising_hand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x87"), ":bow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xa6"), ":face_palm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb7"), ":shrug:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x86"), ":massage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x87"), ":haircut:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb6"), ":walking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x83"), ":runner:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x83"), ":dancer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xba"), ":man_dancing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xaf"), ":dancers:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xa3"), ":speaking_head:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa4"), ":bust_in_silhouette:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa5"), ":busts_in_silhouette:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xab"), ":couple:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xac"), ":two_men_holding_hands:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xad"), ":two_women_holding_hands:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8f"), ":couplekiss:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x91"), ":couple_with_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xaa"), ":family:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xaa"), ":muscle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb3"), ":selfie:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x88"), ":point_left:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x89"), ":point_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x9d"), ":point_up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x86"), ":point_up_2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x95"), ":middle_finger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x87"), ":point_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x8c"), ":v:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x9e"), ":fingers_crossed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x96"), ":vulcan:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x98"), ":metal:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x99"), ":call_me:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x90"), ":hand_splayed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x8b"), ":raised_hand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8c"), ":ok_hand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8d"), ":thumbsup:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8e"), ":thumbsdown:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x8a"), ":fist:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8a"), ":punch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x9b"), ":left_facing_fist:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x9c"), ":right_facing_fist:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x9a"), ":raised_back_of_hand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8b"), ":wave:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x8f"), ":clap:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x8d"), ":writing_hand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x90"), ":open_hands:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8c"), ":raised_hands:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8f"), ":pray:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\x9d"), ":handshake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x85"), ":nail_care:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x82"), ":ear:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x83"), ":nose:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa3"), ":footprints:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x80"), ":eyes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x81"), ":eye:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x85"), ":tongue:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x84"), ":lips:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8b"), ":kiss:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa4"), ":zzz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x93"), ":eyeglasses:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb6"), ":dark_sunglasses:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x94"), ":necktie:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x95"), ":shirt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x96"), ":jeans:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x97"), ":dress:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x98"), ":kimono:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x99"), ":bikini:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9a"), ":womans_clothes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9b"), ":purse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9c"), ":handbag:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9d"), ":pouch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x92"), ":school_satchel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9e"), ":mans_shoe:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x9f"), ":athletic_shoe:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa0"), ":high_heel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa1"), ":sandal:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xa2"), ":boot:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x91"), ":crown:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x92"), ":womans_hat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa9"), ":tophat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x93"), ":mortar_board:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x91"), ":helmet_with_cross:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x84"), ":lipstick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8d"), ":ring:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x82"), ":closed_umbrella:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xbc"), ":briefcase:" }),
    };

    const QVariantList EmojiModel.nature = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x88"), ":see_no_evil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x89"), ":hear_no_evil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x99\x8a"), ":speak_no_evil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa6"), ":sweat_drops:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa8"), ":dash:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb5"), ":monkey_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x92"), ":monkey:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8d"), ":gorilla:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb6"), ":dog:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x95"), ":dog2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa9"), ":poodle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xba"), ":wolf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8a"), ":fox:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb1"), ":cat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x88"), ":cat2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x81"), ":lion_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xaf"), ":tiger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x85"), ":tiger2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x86"), ":leopard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb4"), ":horse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8e"), ":racehorse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8c"), ":deer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x84"), ":unicorn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xae"), ":cow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x82"), ":ox:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x83"), ":water_buffalo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x84"), ":cow2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb7"), ":pig:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x96"), ":pig2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x97"), ":boar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xbd"), ":pig_nose:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8f"), ":ram:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x91"), ":sheep:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x90"), ":goat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xaa"), ":dromedary_camel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xab"), ":camel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x98"), ":elephant:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8f"), ":rhino:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xad"), ":mouse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x81"), ":mouse2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x80"), ":rat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb9"), ":hamster:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb0"), ":rabbit:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x87"), ":rabbit2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xbf"), ":chipmunk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x87"), ":bat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xbb"), ":bear:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa8"), ":koala:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xbc"), ":panda_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xbe"), ":feet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x83"), ":turkey:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x94"), ":chicken:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x93"), ":rooster:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa3"), ":hatching_chick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa4"), ":baby_chick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa5"), ":hatched_chick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa6"), ":bird:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa7"), ":penguin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x8a"), ":dove:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x85"), ":eagle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x86"), ":duck:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x89"), ":owl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb8"), ":frog:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8a"), ":crocodile:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa2"), ":turtle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8e"), ":lizard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8d"), ":snake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb2"), ":dragon_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x89"), ":dragon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xb3"), ":whale:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8b"), ":whale2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xac"), ":dolphin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9f"), ":fish:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa0"), ":tropical_fish:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\xa1"), ":blowfish:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x88"), ":shark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x99"), ":octopus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9a"), ":shell:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x80"), ":crab:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x90"), ":shrimp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x91"), ":squid:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x8b"), ":butterfly:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x8c"), ":snail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9b"), ":bug:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9c"), ":ant:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9d"), ":bee:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x90\x9e"), ":beetle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb7"), ":spider:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb8"), ":spider_web:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa6\x82"), ":scorpion:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x90"), ":bouquet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb8"), ":cherry_blossom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb5"), ":rosette:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb9"), ":rose:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x80"), ":wilted_rose:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xba"), ":hibiscus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xbb"), ":sunflower:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xbc"), ":blossom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb7"), ":tulip:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb1"), ":seedling:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb2"), ":evergreen_tree:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb3"), ":deciduous_tree:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb4"), ":palm_tree:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb5"), ":cactus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xbe"), ":ear_of_rice:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xbf"), ":herb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x98"), ":shamrock:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x80"), ":four_leaf_clover:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x81"), ":maple_leaf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x82"), ":fallen_leaf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x83"), ":leaves:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x84"), ":mushroom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb0"), ":chestnut:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8d"), ":earth_africa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8e"), ":earth_americas:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8f"), ":earth_asia:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x91"), ":new_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x92"), ":waxing_crescent_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x93"), ":first_quarter_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x94"), ":waxing_gibbous_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x95"), ":full_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x96"), ":waning_gibbous_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x97"), ":last_quarter_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x98"), ":waning_crescent_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x99"), ":crescent_moon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9a"), ":new_moon_with_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9b"), ":first_quarter_moon_with_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9c"), ":last_quarter_moon_with_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x80"), ":sunny:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9d"), ":full_moon_with_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9e"), ":sun_with_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xad\x90"), ":star:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x9f"), ":star2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x81"), ":cloud:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x85"), ":partly_sunny:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x88"), ":thunder_cloud_rain:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa4"), ":white_sun_small_cloud:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa5"), ":white_sun_cloud:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa6"), ":white_sun_rain_cloud:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa7"), ":cloud_rain:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa8"), ":cloud_snow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa9"), ":cloud_lightning:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xaa"), ":cloud_tornado:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xab"), ":fog:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xac"), ":wind_blowing_face:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x82"), ":umbrella2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x94"), ":umbrella:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xa1"), ":zap:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x84"), ":snowflake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x83"), ":snowman2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x84"), ":snowman:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x84"), ":comet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa5"), ":fire:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa7"), ":droplet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8a"), ":ocean:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x83"), ":jack_o_lantern:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x84"), ":christmas_tree:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\xa8"), ":sparkles:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8b"), ":tanabata_tree:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8d"), ":bamboo:" }),
    };

    const QVariantList EmojiModel.food = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x87"), ":grapes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x88"), ":melon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x89"), ":watermelon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8a"), ":tangerine:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8b"), ":lemon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8c"), ":banana:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8d"), ":pineapple:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8e"), ":apple:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x8f"), ":green_apple:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x90"), ":pear:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x91"), ":peach:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x92"), ":cherries:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x93"), ":strawberry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x9d"), ":kiwi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x85"), ":tomato:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x91"), ":avocado:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x86"), ":eggplant:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x94"), ":potato:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x95"), ":carrot:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xbd"), ":corn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xb6"), ":hot_pepper:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x92"), ":cucumber:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x9c"), ":peanuts:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9e"), ":bread:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x90"), ":croissant:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x96"), ":french_bread:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x9e"), ":pancakes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa7\x80"), ":cheese:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x96"), ":meat_on_bone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x97"), ":poultry_leg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x93"), ":bacon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x94"), ":hamburger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9f"), ":fries:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x95"), ":pizza:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xad"), ":hotdog:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xae"), ":taco:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xaf"), ":burrito:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x99"), ":stuffed_flatbread:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x9a"), ":egg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb3"), ":cooking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x98"), ":shallow_pan_of_food:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb2"), ":stew:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x97"), ":salad:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xbf"), ":popcorn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb1"), ":bento:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x98"), ":rice_cracker:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x99"), ":rice_ball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9a"), ":rice:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9b"), ":curry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9c"), ":ramen:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\x9d"), ":spaghetti:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa0"), ":sweet_potato:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa2"), ":oden:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa3"), ":sushi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa4"), ":fried_shrimp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa5"), ":fish_cake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa1"), ":dango:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa6"), ":icecream:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa7"), ":shaved_ice:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa8"), ":ice_cream:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xa9"), ":doughnut:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xaa"), ":cookie:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x82"), ":birthday:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb0"), ":cake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xab"), ":chocolate_bar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xac"), ":candy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xad"), ":lollipop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xae"), ":custard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xaf"), ":honey_pot:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xbc"), ":baby_bottle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x9b"), ":milk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x95"), ":coffee:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb5"), ":tea:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb6"), ":sake:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xbe"), ":champagne:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb7"), ":wine_glass:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb8"), ":cocktail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb9"), ":tropical_drink:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xba"), ":beer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xbb"), ":beers:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x82"), ":champagne_glass:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x83"), ":tumbler_glass:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xbd"), ":fork_knife_plate:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8d\xb4"), ":fork_and_knife:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x84"), ":spoon:" }),
    };

    const QVariantList EmojiModel.activity = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\xbe"), ":space_invader:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb4"), ":levitate:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xba"), ":fencer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87"), ":horse_racing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87\xf0\x9f\x8f\xbb"), ":horse_racing_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87\xf0\x9f\x8f\xbc"), ":horse_racing_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87\xf0\x9f\x8f\xbd"), ":horse_racing_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87\xf0\x9f\x8f\xbe"), ":horse_racing_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x87\xf0\x9f\x8f\xbf"), ":horse_racing_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb7"), ":skier:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x82"), ":snowboarder:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8c"), ":golfer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84"), ":surfer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84\xf0\x9f\x8f\xbb"), ":surfer_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84\xf0\x9f\x8f\xbc"), ":surfer_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84\xf0\x9f\x8f\xbd"), ":surfer_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84\xf0\x9f\x8f\xbe"), ":surfer_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x84\xf0\x9f\x8f\xbf"), ":surfer_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3"), ":rowboat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3\xf0\x9f\x8f\xbb"), ":rowboat_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3\xf0\x9f\x8f\xbc"), ":rowboat_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3\xf0\x9f\x8f\xbd"), ":rowboat_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3\xf0\x9f\x8f\xbe"), ":rowboat_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa3\xf0\x9f\x8f\xbf"), ":rowboat_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a"), ":swimmer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a\xf0\x9f\x8f\xbb"), ":swimmer_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a\xf0\x9f\x8f\xbc"), ":swimmer_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a\xf0\x9f\x8f\xbd"), ":swimmer_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a\xf0\x9f\x8f\xbe"), ":swimmer_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8a\xf0\x9f\x8f\xbf"), ":swimmer_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9"), ":basketball_player:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9\xf0\x9f\x8f\xbb"), ":basketball_player_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9\xf0\x9f\x8f\xbc"), ":basketball_player_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9\xf0\x9f\x8f\xbd"), ":basketball_player_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9\xf0\x9f\x8f\xbe"), ":basketball_player_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb9\xf0\x9f\x8f\xbf"), ":basketball_player_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b"), ":lifter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b\xf0\x9f\x8f\xbb"), ":lifter_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b\xf0\x9f\x8f\xbc"), ":lifter_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b\xf0\x9f\x8f\xbd"), ":lifter_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b\xf0\x9f\x8f\xbe"), ":lifter_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8b\xf0\x9f\x8f\xbf"), ":lifter_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4"), ":bicyclist:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4\xf0\x9f\x8f\xbb"), ":bicyclist_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4\xf0\x9f\x8f\xbc"), ":bicyclist_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4\xf0\x9f\x8f\xbd"), ":bicyclist_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4\xf0\x9f\x8f\xbe"), ":bicyclist_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb4\xf0\x9f\x8f\xbf"), ":bicyclist_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5"), ":mountain_bicyclist:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5\xf0\x9f\x8f\xbb"), ":mountain_bicyclist_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5\xf0\x9f\x8f\xbc"), ":mountain_bicyclist_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5\xf0\x9f\x8f\xbd"), ":mountain_bicyclist_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5\xf0\x9f\x8f\xbe"), ":mountain_bicyclist_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb5\xf0\x9f\x8f\xbf"), ":mountain_bicyclist_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8"), ":cartwheel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8\xf0\x9f\x8f\xbb"), ":cartwheel_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8\xf0\x9f\x8f\xbc"), ":cartwheel_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8\xf0\x9f\x8f\xbd"), ":cartwheel_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8\xf0\x9f\x8f\xbe"), ":cartwheel_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb8\xf0\x9f\x8f\xbf"), ":cartwheel_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc"), ":wrestlers:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc\xf0\x9f\x8f\xbb"), ":wrestlers_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc\xf0\x9f\x8f\xbc"), ":wrestlers_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc\xf0\x9f\x8f\xbd"), ":wrestlers_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc\xf0\x9f\x8f\xbe"), ":wrestlers_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbc\xf0\x9f\x8f\xbf"), ":wrestlers_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd"), ":water_polo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd\xf0\x9f\x8f\xbb"), ":water_polo_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd\xf0\x9f\x8f\xbc"), ":water_polo_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd\xf0\x9f\x8f\xbd"), ":water_polo_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd\xf0\x9f\x8f\xbe"), ":water_polo_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbd\xf0\x9f\x8f\xbf"), ":water_polo_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe"), ":handball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe\xf0\x9f\x8f\xbb"), ":handball_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe\xf0\x9f\x8f\xbc"), ":handball_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe\xf0\x9f\x8f\xbd"), ":handball_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe\xf0\x9f\x8f\xbe"), ":handball_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xbe\xf0\x9f\x8f\xbf"), ":handball_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9"), ":juggling:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9\xf0\x9f\x8f\xbb"), ":juggling_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9\xf0\x9f\x8f\xbc"), ":juggling_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9\xf0\x9f\x8f\xbd"), ":juggling_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9\xf0\x9f\x8f\xbe"), ":juggling_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa4\xb9\xf0\x9f\x8f\xbf"), ":juggling_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xaa"), ":circus_tent:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xad"), ":performing_arts:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa8"), ":art:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb0"), ":slot_machine:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80"), ":bath:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80\xf0\x9f\x8f\xbb"), ":bath_tone1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80\xf0\x9f\x8f\xbc"), ":bath_tone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80\xf0\x9f\x8f\xbd"), ":bath_tone3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80\xf0\x9f\x8f\xbe"), ":bath_tone4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x80\xf0\x9f\x8f\xbf"), ":bath_tone5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x97"), ":reminder_ribbon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x9f"), ":tickets:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xab"), ":ticket:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x96"), ":military_medal:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x86"), ":trophy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x85"), ":medal:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x87"), ":first_place:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x88"), ":second_place:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x89"), ":third_place:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xbd"), ":soccer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xbe"), ":baseball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x80"), ":basketball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x90"), ":volleyball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x88"), ":football:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x89"), ":rugby_football:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xbe"), ":tennis:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb1"), ":8ball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb3"), ":bowling:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8f"), ":cricket:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x91"), ":field_hockey:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x92"), ":hockey:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x93"), ":ping_pong:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb8"), ":badminton:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x8a"), ":boxing_glove:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x8b"), ":martial_arts_uniform:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x85"), ":goal:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xaf"), ":dart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb3"), ":golf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb8"), ":ice_skate:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa3"), ":fishing_pole_and_fish:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xbd"), ":running_shirt_with_sash:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xbf"), ":ski:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xae"), ":video_game:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb2"), ":game_die:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xbc"), ":musical_score:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa4"), ":microphone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa7"), ":headphones:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb7"), ":saxophone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb8"), ":guitar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb9"), ":musical_keyboard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xba"), ":trumpet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xbb"), ":violin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\xa5\x81"), ":drum:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xac"), ":clapper:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb9"), ":bow_and_arrow:" }),
    };

    const QVariantList EmojiModel.travel = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8e"), ":race_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x8d"), ":motorcycle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xbe"), ":japan:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x94"), ":mountain_snow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb0"), ":mountain:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8b"), ":volcano:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xbb"), ":mount_fuji:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x95"), ":camping:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x96"), ":beach:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9c"), ":desert:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9d"), ":island:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9e"), ":park:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9f"), ":stadium:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9b"), ":classical_building:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x97"), ":construction_site:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x98"), ":homes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x99"), ":cityscape:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x9a"), ":house_abandoned:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa0"), ":house:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa1"), ":house_with_garden:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa2"), ":office:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa3"), ":post_office:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa4"), ":european_post_office:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa5"), ":hospital:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa6"), ":bank:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa8"), ":hotel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa9"), ":love_hotel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xaa"), ":convenience_store:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xab"), ":school:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xac"), ":department_store:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xad"), ":factory:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xaf"), ":japanese_castle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb0"), ":european_castle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x92"), ":wedding:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xbc"), ":tokyo_tower:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xbd"), ":statue_of_liberty:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xaa"), ":church:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x8c"), ":mosque:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x8d"), ":synagogue:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xa9"), ":shinto_shrine:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x8b"), ":kaaba:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb2"), ":fountain:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xba"), ":tent:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x81"), ":foggy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x83"), ":night_with_stars:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x84"), ":sunrise_over_mountains:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x85"), ":sunrise:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x86"), ":city_dusk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x87"), ":city_sunset:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x89"), ":bridge_at_night:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x8c"), ":milky_way:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa0"), ":carousel_horse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa1"), ":ferris_wheel:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa2"), ":roller_coaster:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x82"), ":steam_locomotive:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x83"), ":railway_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x84"), ":bullettrain_side:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x85"), ":bullettrain_front:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x86"), ":train2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x87"), ":metro:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x88"), ":light_rail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x89"), ":station:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8a"), ":tram:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9d"), ":monorail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9e"), ":mountain_railway:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8b"), ":train:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8c"), ":bus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8d"), ":oncoming_bus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8e"), ":trolleybus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x90"), ":minibus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x91"), ":ambulance:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x92"), ":fire_engine:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x93"), ":police_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x94"), ":oncoming_police_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x95"), ":taxi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x96"), ":oncoming_taxi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x97"), ":red_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x98"), ":oncoming_automobile:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x99"), ":blue_car:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9a"), ":truck:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9b"), ":articulated_lorry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9c"), ":tractor:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb2"), ":bike:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xb4"), ":scooter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xb5"), ":motor_scooter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x8f"), ":busstop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa3"), ":motorway:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa4"), ":railway_track:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xbd"), ":fuelpump:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa8"), ":rotating_light:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa5"), ":traffic_light:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa6"), ":vertical_traffic_light:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa7"), ":construction:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x93"), ":anchor:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb5"), ":sailboat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xb6"), ":canoe:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa4"), ":speedboat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xb3"), ":cruise_ship:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb4"), ":ferry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa5"), ":motorboat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa2"), ":ship:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x88"), ":airplane:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa9"), ":airplane_small:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xab"), ":airplane_departure:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xac"), ":airplane_arriving:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xba"), ":seat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x81"), ":helicopter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x9f"), ":suspension_railway:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa0"), ":mountain_cableway:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa1"), ":aerial_tramway:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\x80"), ":rocket:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xb0"), ":satellite_orbital:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa0"), ":stars:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x88"), ":rainbow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x86"), ":fireworks:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x87"), ":sparkler:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x91"), ":rice_scene:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\x81"), ":checkered_flag:" }),
    };

    const QVariantList EmojiModel.objects = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xa0"), ":skull_crossbones:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8c"), ":love_letter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa3"), ":bomb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb3"), ":hole:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x8d"), ":shopping_bags:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xbf"), ":prayer_beads:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8e"), ":gem:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xaa"), ":knife:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xba"), ":amphora:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xba"), ":map:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x88"), ":barber:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xbc"), ":frame_photo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x8e"), ":bellhop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xaa"), ":door:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x8c"), ":sleeping_accommodation:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x8f"), ":bed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x8b"), ":couch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xbd"), ":toilet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xbf"), ":shower:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x81"), ":bathtub:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8c\x9b"), ":hourglass:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb3"), ":hourglass_flowing_sand:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8c\x9a"), ":watch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb0"), ":alarm_clock:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb1"), ":stopwatch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb2"), ":timer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb0"), ":clock:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\xa1"), ":thermometer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\xb1"), ":beach_umbrella:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x88"), ":balloon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x89"), ":tada:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8a"), ":confetti_ball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8e"), ":dolls:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8f"), ":flags:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x90"), ":wind_chime:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x80"), ":ribbon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x81"), ":gift:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xb9"), ":joystick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xaf"), ":postal_horn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x99"), ":microphone2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x9a"), ":level_slider:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x9b"), ":control_knobs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xbb"), ":radio:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb1"), ":iphone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb2"), ":calling:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x8e"), ":telephone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9e"), ":telephone_receiver:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9f"), ":pager:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa0"), ":fax:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8b"), ":battery:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8c"), ":electric_plug:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xbb"), ":computer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xa5"), ":desktop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xa8"), ":printer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8c\xa8"), ":keyboard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xb1"), ":mouse_three_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xb2"), ":trackball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xbd"), ":minidisc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xbe"), ":floppy_disk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xbf"), ":cd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x80"), ":dvd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa5"), ":movie_camera:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x9e"), ":film_frames:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xbd"), ":projector:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xba"), ":tv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb7"), ":camera:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb8"), ":camera_with_flash:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb9"), ":video_camera:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xbc"), ":vhs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8d"), ":mag:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8e"), ":mag_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xac"), ":microscope:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xad"), ":telescope:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa1"), ":satellite:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xaf"), ":candle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa1"), ":bulb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa6"), ":flashlight:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xae"), ":izakaya_lantern:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x94"), ":notebook_with_decorative_cover:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x95"), ":closed_book:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x96"), ":book:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x97"), ":green_book:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x98"), ":blue_book:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x99"), ":orange_book:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9a"), ":books:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x93"), ":notebook:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x92"), ":ledger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x83"), ":page_with_curl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9c"), ":scroll:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x84"), ":page_facing_up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb0"), ":newspaper:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x9e"), ":newspaper2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x91"), ":bookmark_tabs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x96"), ":bookmark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb7"), ":label:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb0"), ":moneybag:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb4"), ":yen:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb5"), ":dollar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb6"), ":euro:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb7"), ":pound:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb8"), ":money_with_wings:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb3"), ":credit_card:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x89"), ":envelope:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa7"), ":e-mail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa8"), ":incoming_envelope:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa9"), ":envelope_with_arrow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa4"), ":outbox_tray:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa5"), ":inbox_tray:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa6"), ":package:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xab"), ":mailbox:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xaa"), ":mailbox_closed:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xac"), ":mailbox_with_mail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xad"), ":mailbox_with_no_mail:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xae"), ":postbox:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xb3"), ":ballot_box:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x8f"), ":pencil2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x92"), ":black_nib:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x8b"), ":pen_fountain:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x8a"), ":pen_ballpoint:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x8c"), ":paintbrush:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x8d"), ":crayon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9d"), ":pencil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x81"), ":file_folder:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x82"), ":open_file_folder:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x82"), ":dividers:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x85"), ":date:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x86"), ":calendar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x92"), ":notepad_spiral:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x93"), ":calendar_spiral:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x87"), ":card_index:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x88"), ":chart_with_upwards_trend:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x89"), ":chart_with_downwards_trend:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8a"), ":bar_chart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8b"), ":clipboard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8c"), ":pushpin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8d"), ":round_pushpin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8e"), ":paperclip:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\x87"), ":paperclips:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x8f"), ":straight_ruler:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x90"), ":triangular_ruler:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x82"), ":scissors:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x83"), ":card_box:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x84"), ":file_cabinet:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x91"), ":wastebasket:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x92"), ":lock:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x93"), ":unlock:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8f"), ":lock_with_ink_pen:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x90"), ":closed_lock_with_key:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x91"), ":key:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x9d"), ":key2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa8"), ":hammer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x8f"), ":pick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x92"), ":hammer_pick:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa0"), ":tools:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xa1"), ":dagger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x94"), ":crossed_swords:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xab"), ":gun:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa1"), ":shield:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa7"), ":wrench:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa9"), ":nut_and_bolt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x99"), ":gear:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\x9c"), ":compression:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x97"), ":alembic:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x96"), ":scales:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x97"), ":link:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x93"), ":chains:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x89"), ":syringe:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x8a"), ":pill:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xac"), ":smoking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xb0"), ":coffin:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xb1"), ":urn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xbf"), ":moyai:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\xa2"), ":oil:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xae"), ":crystal_ball:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x92"), ":shopping_cart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xa9"), ":triangular_flag_on_post:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\x8c"), ":crossed_flags:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb4"), ":flag_black:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb3"), ":flag_white:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xb3\xf0\x9f\x8c\x88"), ":rainbow_flag:" }),
    };

    const QVariantList EmojiModel.symbols = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x91\x81\xf0\x9f\x97\xa8"), ":eye_in_speech_bubble:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x98"), ":cupid:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\xa4"), ":heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x93"), ":heartbeat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x94"), ":broken_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x95"), ":two_hearts:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x96"), ":sparkling_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x97"), ":heartpulse:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x99"), ":blue_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9a"), ":green_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9b"), ":yellow_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9c"), ":purple_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x96\xa4"), ":black_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9d"), ":gift_heart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9e"), ":revolving_hearts:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\x9f"), ":heart_decoration:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\xa3"), ":heart_exclamation:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa2"), ":anger:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa5"), ":boom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xab"), ":dizzy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xac"), ":speech_balloon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xa8"), ":speech_left:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x97\xaf"), ":anger_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xad"), ":thought_balloon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xae"), ":white_flower:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x90"), ":globe_with_meridians:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xa8"), ":hotsprings:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x91"), ":octagonal_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9b"), ":clock12:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa7"), ":clock1230:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x90"), ":clock1:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9c"), ":clock130:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x91"), ":clock2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9d"), ":clock230:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x92"), ":clock3:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9e"), ":clock330:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x93"), ":clock4:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9f"), ":clock430:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x94"), ":clock5:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa0"), ":clock530:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x95"), ":clock6:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa1"), ":clock630:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x96"), ":clock7:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa2"), ":clock730:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x97"), ":clock8:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa3"), ":clock830:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x98"), ":clock9:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa4"), ":clock930:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x99"), ":clock10:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa5"), ":clock1030:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x9a"), ":clock11:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\xa6"), ":clock1130:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8c\x80"), ":cyclone:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xa0"), ":spades:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xa5"), ":hearts:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xa6"), ":diamonds:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xa3"), ":clubs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x83\x8f"), ":black_joker:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x80\x84"), ":mahjong:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb4"), ":flower_playing_cards:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x87"), ":mute:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x88"), ":speaker:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x89"), ":sound:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x8a"), ":loud_sound:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa2"), ":loudspeaker:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xa3"), ":mega:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x94"), ":bell:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x95"), ":no_bell:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb5"), ":musical_note:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xb6"), ":notes:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb9"), ":chart:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb1"), ":currency_exchange:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xb2"), ":heavy_dollar_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8f\xa7"), ":atm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xae"), ":put_litter_in_its_place:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb0"), ":potable_water:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xbf"), ":wheelchair:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb9"), ":mens:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xba"), ":womens:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xbb"), ":restroom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xbc"), ":baby_symbol:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xbe"), ":wc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x82"), ":passport_control:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x83"), ":customs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x84"), ":baggage_claim:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x85"), ":left_luggage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xa0"), ":warning:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb8"), ":children_crossing:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x94"), ":no_entry:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xab"), ":no_entry_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb3"), ":no_bicycles:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xad"), ":no_smoking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xaf"), ":do_not_litter:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb1"), ":non-potable_water:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9a\xb7"), ":no_pedestrians:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb5"), ":no_mobile_phones:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9e"), ":underage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xa2"), ":radioactive:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xa3"), ":biohazard:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xac\x86"), ":arrow_up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x97"), ":arrow_upper_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\xa1"), ":arrow_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x98"), ":arrow_lower_right:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xac\x87"), ":arrow_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x99"), ":arrow_lower_left:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xac\x85"), ":arrow_left:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x96"), ":arrow_upper_left:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x95"), ":arrow_up_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\x94"), ":left_right_arrow:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\xa9"), ":leftwards_arrow_with_hook:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x86\xaa"), ":arrow_right_hook:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xa4\xb4"), ":arrow_heading_up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xa4\xb5"), ":arrow_heading_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x83"), ":arrows_clockwise:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x84"), ":arrows_counterclockwise:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x99"), ":back:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9a"), ":end:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9b"), ":on:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9c"), ":soon:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9d"), ":top:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x9b\x90"), ":place_of_worship:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x9b"), ":atom:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x89"), ":om_symbol:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\xa1"), ":star_of_david:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xb8"), ":wheel_of_dharma:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xaf"), ":yin_yang:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x9d"), ":cross:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xa6"), ":orthodox_cross:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xaa"), ":star_and_crescent:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\xae"), ":peace:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x95\x8e"), ":menorah:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xaf"), ":six_pointed_star:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x88"), ":aries:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x89"), ":taurus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8a"), ":gemini:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8b"), ":cancer:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8c"), ":leo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8d"), ":virgo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8e"), ":libra:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x8f"), ":scorpius:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x90"), ":sagittarius:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x91"), ":capricorn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x92"), ":aquarius:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\x93"), ":pisces:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9b\x8e"), ":ophiuchus:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x80"), ":twisted_rightwards_arrows:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x81"), ":repeat:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x82"), ":repeat_one:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x96\xb6"), ":arrow_forward:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xa9"), ":fast_forward:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xad"), ":track_next:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xaf"), ":play_pause:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x97\x80"), ":arrow_backward:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xaa"), ":rewind:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xae"), ":track_previous:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xbc"), ":arrow_up_small:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xab"), ":arrow_double_up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xbd"), ":arrow_down_small:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xac"), ":arrow_double_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb8"), ":pause_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xb9"), ":stop_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\xba"), ":record_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x8f\x8f"), ":eject:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x8e\xa6"), ":cinema:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x85"), ":low_brightness:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x86"), ":high_brightness:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb6"), ":signal_strength:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb3"), ":vibration_mode:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\xb4"), ":mobile_phone_off:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x99\xbb"), ":recycle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x93\x9b"), ":name_badge:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\x9c"), ":fleur-de-lis:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb0"), ":beginner:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb1"), ":trident:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xad\x95"), ":o:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x85"), ":white_check_mark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x98\x91"), ":ballot_box_with_check:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x94"), ":heavy_check_mark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\x96"), ":heavy_multiplication_x:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x8c"), ":x:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x8e"), ":negative_squared_cross_mark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\x95"), ":heavy_plus_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\x96"), ":heavy_minus_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\x97"), ":heavy_division_sign:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\xb0"), ":curly_loop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9e\xbf"), ":loop:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe3\x80\xbd"), ":part_alternation_mark:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\xb3"), ":eight_spoked_asterisk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9c\xb4"), ":eight_pointed_black_star:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x87"), ":sparkle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x80\xbc"), ":bangbang:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x81\x89"), ":interrobang:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x93"), ":question:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x94"), ":grey_question:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x95"), ":grey_exclamation:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9d\x97"), ":exclamation:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe3\x80\xb0"), ":wavy_dash:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xc2\xa9"), ":copyright:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xc2\xae"), ":registered:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x84\xa2"), ":tm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("#\xe2\x83\xa3"), ":hash:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("*\xe2\x83\xa3"), ":asterisk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("0\xe2\x83\xa3"), ":zero:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("1\xe2\x83\xa3"), ":one:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("2\xe2\x83\xa3"), ":two:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("3\xe2\x83\xa3"), ":three:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("4\xe2\x83\xa3"), ":four:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("5\xe2\x83\xa3"), ":five:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("6\xe2\x83\xa3"), ":six:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("7\xe2\x83\xa3"), ":seven:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("8\xe2\x83\xa3"), ":eight:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("9\xe2\x83\xa3"), ":nine:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x9f"), ":keycap_ten:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xaf"), ":100:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa0"), ":capital_abcd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa1"), ":abcd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa2"), ":1234:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa3"), ":symbols:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xa4"), ":abc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x85\xb0"), ":a:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x8e"), ":ab:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x85\xb1"), ":b:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x91"), ":cl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x92"), ":cool:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x93"), ":free:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x84\xb9"), ":information_source:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x94"), ":id:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x93\x82"), ":m:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x95"), ":new:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x96"), ":ng:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x85\xbe"), ":o2:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x97"), ":ok:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x85\xbf"), ":parking:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x98"), ":sos:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x99"), ":up:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x86\x9a"), ":vs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\x81"), ":koko:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\x82"), ":sa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb7"), ":u6708:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb6"), ":u6709:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xaf"), ":u6307:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x89\x90"), ":ideograph_advantage:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb9"), ":u5272:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\x9a"), ":u7121:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb2"), ":u7981:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x89\x91"), ":accept:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb8"), ":u7533:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb4"), ":u5408:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb3"), ":u7a7a:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe3\x8a\x97"), ":congratulations:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe3\x8a\x99"), ":secret:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xba"), ":u55b6:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x88\xb5"), ":u6e80:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x96\xaa"), ":black_small_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x96\xab"), ":white_small_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x97\xbb"), ":white_medium_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x97\xbc"), ":black_medium_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x97\xbd"), ":white_medium_small_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x97\xbe"), ":black_medium_small_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xac\x9b"), ":black_large_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\xac\x9c"), ":white_large_square:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb6"), ":large_orange_diamond:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb7"), ":large_blue_diamond:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb8"), ":small_orange_diamond:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb9"), ":small_blue_diamond:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xba"), ":small_red_triangle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xbb"), ":small_red_triangle_down:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x92\xa0"), ":diamond_shape_with_a_dot_inside:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\x98"), ":radio_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb2"), ":black_square_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb3"), ":white_square_button:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xaa"), ":white_circle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xe2\x9a\xab"), ":black_circle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb4"), ":red_circle:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x94\xb5"), ":blue_circle:" }),
    };

    const QVariantList EmojiModel.flags = {
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xa8"), ":flag_ac:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xa9"), ":flag_ad:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xaa"), ":flag_ae:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xab"), ":flag_af:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xac"), ":flag_ag:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xae"), ":flag_ai:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb1"), ":flag_al:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb2"), ":flag_am:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb4"), ":flag_ao:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb6"), ":flag_aq:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb7"), ":flag_ar:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb8"), ":flag_as:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xb9"), ":flag_at:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xba"), ":flag_au:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xbc"), ":flag_aw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xbd"), ":flag_ax:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa6\xf0\x9f\x87\xbf"), ":flag_az:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xa6"), ":flag_ba:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xa7"), ":flag_bb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xa9"), ":flag_bd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xaa"), ":flag_be:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xab"), ":flag_bf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xac"), ":flag_bg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xad"), ":flag_bh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xae"), ":flag_bi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xaf"), ":flag_bj:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb1"), ":flag_bl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb2"), ":flag_bm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb3"), ":flag_bn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb4"), ":flag_bo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb6"), ":flag_bq:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb7"), ":flag_br:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb8"), ":flag_bs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xb9"), ":flag_bt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xbb"), ":flag_bv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xbc"), ":flag_bw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xbe"), ":flag_by:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa7\xf0\x9f\x87\xbf"), ":flag_bz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xa6"), ":flag_ca:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xa8"), ":flag_cc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xa9"), ":flag_cd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xab"), ":flag_cf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xac"), ":flag_cg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xad"), ":flag_ch:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xae"), ":flag_ci:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb0"), ":flag_ck:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb1"), ":flag_cl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb2"), ":flag_cm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb3"), ":flag_cn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb4"), ":flag_co:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb5"), ":flag_cp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xb7"), ":flag_cr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xba"), ":flag_cu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xbb"), ":flag_cv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xbc"), ":flag_cw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xbd"), ":flag_cx:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xbe"), ":flag_cy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa8\xf0\x9f\x87\xbf"), ":flag_cz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xaa"), ":flag_de:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xac"), ":flag_dg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xaf"), ":flag_dj:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xb0"), ":flag_dk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xb2"), ":flag_dm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xb4"), ":flag_do:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xa9\xf0\x9f\x87\xbf"), ":flag_dz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xa6"), ":flag_ea:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xa8"), ":flag_ec:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xaa"), ":flag_ee:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xac"), ":flag_eg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xad"), ":flag_eh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xb7"), ":flag_er:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xb8"), ":flag_es:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xb9"), ":flag_et:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaa\xf0\x9f\x87\xba"), ":flag_eu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xae"), ":flag_fi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xaf"), ":flag_fj:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xb0"), ":flag_fk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xb2"), ":flag_fm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xb4"), ":flag_fo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xab\xf0\x9f\x87\xb7"), ":flag_fr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xa6"), ":flag_ga:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xa7"), ":flag_gb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xa9"), ":flag_gd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xaa"), ":flag_ge:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xab"), ":flag_gf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xac"), ":flag_gg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xad"), ":flag_gh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xae"), ":flag_gi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb1"), ":flag_gl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb2"), ":flag_gm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb3"), ":flag_gn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb5"), ":flag_gp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb6"), ":flag_gq:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb7"), ":flag_gr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb8"), ":flag_gs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xb9"), ":flag_gt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xba"), ":flag_gu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xbc"), ":flag_gw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xac\xf0\x9f\x87\xbe"), ":flag_gy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xb0"), ":flag_hk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xb2"), ":flag_hm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xb3"), ":flag_hn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xb7"), ":flag_hr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xb9"), ":flag_ht:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xad\xf0\x9f\x87\xba"), ":flag_hu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xa8"), ":flag_ic:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xa9"), ":flag_id:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xaa"), ":flag_ie:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb1"), ":flag_il:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb2"), ":flag_im:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb3"), ":flag_in:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb4"), ":flag_io:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb6"), ":flag_iq:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb7"), ":flag_ir:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb8"), ":flag_is:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xae\xf0\x9f\x87\xb9"), ":flag_it:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaf\xf0\x9f\x87\xaa"), ":flag_je:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaf\xf0\x9f\x87\xb2"), ":flag_jm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaf\xf0\x9f\x87\xb4"), ":flag_jo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xaf\xf0\x9f\x87\xb5"), ":flag_jp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xaa"), ":flag_ke:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xac"), ":flag_kg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xad"), ":flag_kh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xae"), ":flag_ki:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xb2"), ":flag_km:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xb3"), ":flag_kn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xb5"), ":flag_kp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xb7"), ":flag_kr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xbc"), ":flag_kw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xbe"), ":flag_ky:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb0\xf0\x9f\x87\xbf"), ":flag_kz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xa6"), ":flag_la:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xa7"), ":flag_lb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xa8"), ":flag_lc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xae"), ":flag_li:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xb0"), ":flag_lk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xb7"), ":flag_lr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xb8"), ":flag_ls:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xb9"), ":flag_lt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xba"), ":flag_lu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xbb"), ":flag_lv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb1\xf0\x9f\x87\xbe"), ":flag_ly:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xa6"), ":flag_ma:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xa8"), ":flag_mc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xa9"), ":flag_md:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xaa"), ":flag_me:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xab"), ":flag_mf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xac"), ":flag_mg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xad"), ":flag_mh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb0"), ":flag_mk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb1"), ":flag_ml:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb2"), ":flag_mm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb3"), ":flag_mn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb4"), ":flag_mo:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb5"), ":flag_mp:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb6"), ":flag_mq:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb7"), ":flag_mr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb8"), ":flag_ms:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xb9"), ":flag_mt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xba"), ":flag_mu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xbb"), ":flag_mv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xbc"), ":flag_mw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xbd"), ":flag_mx:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xbe"), ":flag_my:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb2\xf0\x9f\x87\xbf"), ":flag_mz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xa6"), ":flag_na:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xa8"), ":flag_nc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xaa"), ":flag_ne:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xab"), ":flag_nf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xac"), ":flag_ng:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xae"), ":flag_ni:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xb1"), ":flag_nl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xb4"), ":flag_no:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xb5"), ":flag_np:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xb7"), ":flag_nr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xba"), ":flag_nu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb3\xf0\x9f\x87\xbf"), ":flag_nz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb4\xf0\x9f\x87\xb2"), ":flag_om:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xa6"), ":flag_pa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xaa"), ":flag_pe:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xab"), ":flag_pf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xac"), ":flag_pg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xad"), ":flag_ph:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb0"), ":flag_pk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb1"), ":flag_pl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb2"), ":flag_pm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb3"), ":flag_pn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb7"), ":flag_pr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb8"), ":flag_ps:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xb9"), ":flag_pt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xbc"), ":flag_pw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb5\xf0\x9f\x87\xbe"), ":flag_py:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb6\xf0\x9f\x87\xa6"), ":flag_qa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb7\xf0\x9f\x87\xaa"), ":flag_re:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb7\xf0\x9f\x87\xb4"), ":flag_ro:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb7\xf0\x9f\x87\xb8"), ":flag_rs:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb7\xf0\x9f\x87\xba"), ":flag_ru:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb7\xf0\x9f\x87\xbc"), ":flag_rw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xa6"), ":flag_sa:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xa7"), ":flag_sb:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xa8"), ":flag_sc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xa9"), ":flag_sd:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xaa"), ":flag_se:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xac"), ":flag_sg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xad"), ":flag_sh:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xae"), ":flag_si:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xaf"), ":flag_sj:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb0"), ":flag_sk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb1"), ":flag_sl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb2"), ":flag_sm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb3"), ":flag_sn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb4"), ":flag_so:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb7"), ":flag_sr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb8"), ":flag_ss:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xb9"), ":flag_st:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xbb"), ":flag_sv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xbd"), ":flag_sx:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xbe"), ":flag_sy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb8\xf0\x9f\x87\xbf"), ":flag_sz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xa6"), ":flag_ta:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xa8"), ":flag_tc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xa9"), ":flag_td:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xab"), ":flag_tf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xac"), ":flag_tg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xad"), ":flag_th:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xaf"), ":flag_tj:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb0"), ":flag_tk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb1"), ":flag_tl:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb2"), ":flag_tm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb3"), ":flag_tn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb4"), ":flag_to:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb7"), ":flag_tr:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xb9"), ":flag_tt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xbb"), ":flag_tv:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xbc"), ":flag_tw:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xb9\xf0\x9f\x87\xbf"), ":flag_tz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xa6"), ":flag_ua:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xac"), ":flag_ug:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xb2"), ":flag_um:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xb8"), ":flag_us:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xbe"), ":flag_uy:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xba\xf0\x9f\x87\xbf"), ":flag_uz:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xa6"), ":flag_va:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xa8"), ":flag_vc:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xaa"), ":flag_ve:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xac"), ":flag_vg:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xae"), ":flag_vi:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xb3"), ":flag_vn:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbb\xf0\x9f\x87\xba"), ":flag_vu:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbc\xf0\x9f\x87\xab"), ":flag_wf:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbc\xf0\x9f\x87\xb8"), ":flag_ws:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbd\xf0\x9f\x87\xb0"), ":flag_xk:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbe\xf0\x9f\x87\xaa"), ":flag_ye:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbe\xf0\x9f\x87\xb9"), ":flag_yt:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbf\xf0\x9f\x87\xa6"), ":flag_za:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbf\xf0\x9f\x87\xb2"), ":flag_zm:"
        }),
        QVariant.from_value (Emoji {
            string.from_utf8 ("\xf0\x9f\x87\xbf\xf0\x9f\x87\xbc"), ":flag_zw:" }),
    };
    }
    