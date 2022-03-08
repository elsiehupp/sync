/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>

namespace Testing {

class TestIconUtils : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public TestIconUtils () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }


    /***********************************************************
    ***********************************************************/
    private void testDrawSvgWithCustomFillColor () {
        const string blackSvgDirPath = Occ.Theme.themePrefix + "black";
        const QDir blackSvgDir = new QDir (blackSvgDirPath);
        const string[] blackImages = blackSvgDir.entryList ("*.svg");

        //  Q_ASSERT (!blackImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + "/" + blackImages.at (0), QColorConstants.Svg.red).isNull ());

        //  QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + "/" + blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const string whiteSvgDirPath = Occ.Theme.themePrefix + "white";
        const QDir whiteSvgDir = new QDir (whiteSvgDirPath);
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        //  Q_ASSERT (!whiteImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (whiteSvgDirPath + "/" + whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }


    /***********************************************************
    ***********************************************************/
    private void testCreateSvgPixmapWithCustomColor () {
        const QDir blackSvgDir = new QDir (Occ.Theme.themePrefix + "black");
        const string[] blackImages = blackSvgDir.entryList ("*.svg");

        //  QVERIFY (!blackImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.red).isNull ());

        //  QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const QDir whiteSvgDir = new QDir (Occ.Theme.themePrefix + "white");
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        //  QVERIFY (!whiteImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPixmapForBackground () {
        const QDir blackSvgDir = new QDir (Occ.Theme.themePrefix + "black");
        const string[] blackImages = blackSvgDir.entryList ("*.svg");

        const QDir whiteSvgDir = new QDir (Occ.Theme.themePrefix + "white");
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        //  QVERIFY (!blackImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (whiteImages.at (0), Gtk.Color ("blue")).isNull ());

        //  QVERIFY (!whiteImages.isEmpty ());

        //  QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (blackImages.at (0), Gtk.Color ("yellow")).isNull ());
    }

} // class TestIconUtils
} // namespace Testing
