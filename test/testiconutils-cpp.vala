/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTest>

class TestIconUtils : GLib.Object {

public:
    TestIconUtils () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }

private slots:
    void testDrawSvgWithCustomFillColor () {
        const string blackSvgDirPath{string{Occ.Theme.themePrefix} + QStringLiteral ("black")};
        const QDir blackSvgDir (blackSvgDirPath);
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        Q_ASSERT (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const string whiteSvgDirPath{string{Occ.Theme.themePrefix} + QStringLiteral ("white")};
        const QDir whiteSvgDir (whiteSvgDirPath);
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        Q_ASSERT (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (whiteSvgDirPath + QStringLiteral ("/") + whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }

    void testCreateSvgPixmapWithCustomColor () {
        const QDir blackSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const QDir whiteSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }

    void testPixmapForBackground () {
        const QDir blackSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        const QDir whiteSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (whiteImages.at (0), QColor ("blue")).isNull ());

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (blackImages.at (0), QColor ("yellow")).isNull ());
    }
};

QTEST_MAIN (TestIconUtils)
#include "testiconutils.moc"
