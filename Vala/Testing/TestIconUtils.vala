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

        GLib.assert_true (!blackImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + "/" + blackImages.at (0), QColorConstants.Svg.red).is_null ());

        GLib.assert_true (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + "/" + blackImages.at (0), QColorConstants.Svg.green).is_null ());

        const string whiteSvgDirPath = Occ.Theme.themePrefix + "white";
        const QDir whiteSvgDir = new QDir (whiteSvgDirPath);
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        GLib.assert_true (!whiteImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (whiteSvgDirPath + "/" + whiteImages.at (0), QColorConstants.Svg.blue).is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void testCreateSvgPixmapWithCustomColor () {
        const QDir blackSvgDir = new QDir (Occ.Theme.themePrefix + "black");
        const string[] blackImages = blackSvgDir.entryList ("*.svg");

        GLib.assert_true (!blackImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.red).is_null ());

        GLib.assert_true (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.green).is_null ());

        const QDir whiteSvgDir = new QDir (Occ.Theme.themePrefix + "white");
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        GLib.assert_true (!whiteImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (whiteImages.at (0), QColorConstants.Svg.blue).is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void testPixmapForBackground () {
        const QDir blackSvgDir = new QDir (Occ.Theme.themePrefix + "black");
        const string[] blackImages = blackSvgDir.entryList ("*.svg");

        const QDir whiteSvgDir = new QDir (Occ.Theme.themePrefix + "white");
        const string[] whiteImages = whiteSvgDir.entryList ("*.svg");

        GLib.assert_true (!blackImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.pixmapForBackground (whiteImages.at (0), Gtk.Color ("blue")).is_null ());

        GLib.assert_true (!whiteImages.is_empty ());

        GLib.assert_true (!Occ.Ui.IconUtils.pixmapForBackground (blackImages.at (0), Gtk.Color ("yellow")).is_null ());
    }

} // class TestIconUtils
} // namespace Testing
