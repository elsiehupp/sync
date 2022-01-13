/*
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QTest>

class TestIconUtils : GLib.Object {

public:
    TestIconUtils () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }

private slots:
    void testDrawSvgWithCustomFillColor () {
        const QString blackSvgDirPath{QString{Occ.Theme.themePrefix} + QStringLiteral ("black")};
        const QDir blackSvgDir (blackSvgDirPath);
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        Q_ASSERT (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const QString whiteSvgDirPath{QString{Occ.Theme.themePrefix} + QStringLiteral ("white")};
        const QDir whiteSvgDir (whiteSvgDirPath);
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        Q_ASSERT (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (whiteSvgDirPath + QStringLiteral ("/") + whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }

    void testCreateSvgPixmapWithCustomColor () {
        const QDir blackSvgDir (QString (QString{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const QDir whiteSvgDir (QString (QString{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }

    void testPixmapForBackground () {
        const QDir blackSvgDir (QString (QString{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const QStringList blackImages = blackSvgDir.entryList (QStringList ("*.svg"));

        const QDir whiteSvgDir (QString (QString{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const QStringList whiteImages = whiteSvgDir.entryList (QStringList ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (whiteImages.at (0), QColor ("blue")).isNull ());

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (blackImages.at (0), QColor ("yellow")).isNull ());
    }
};

QTEST_MAIN (TestIconUtils)
#include "testiconutils.moc"
