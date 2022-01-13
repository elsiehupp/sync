/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <string>

class QSpinBox;

namespace Occ {

namespace WizardCommon {

    void setupCustomMedia (QVariant &variant, QLabel *label);
    string titleTemplate ();
    string subTitleTemplate ();
    void initErrorLabel (QLabel *errorLabel);
    void customizeHintLabel (QLabel *label);

    enum SyncMode {
        SelectiveMode,
        BoxMode
    };

    enum Pages {
        Page_Welcome,
        Page_ServerSetup,
        Page_HttpCreds,
        Page_OAuthCreds,
        Page_Flow2AuthCreds,
#ifdef WITH_WEBENGINE
        Page_WebView,
#endif // WITH_WEBENGINE
        Page_AdvancedSetup,
    };

} // ns WizardCommon

} // namespace Occ











/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLabel>
// #include <QPixmap>
// #include <QVariant>
// #include <QRadioButton>
// #include <QAbstractButton>
// #include <QCheckBox>
// #include <QSpinBox>

namespace Occ {

    namespace WizardCommon {
    
        void setupCustomMedia (QVariant &variant, QLabel *label) {
            if (!label)
                return;
    
            QPixmap pix = variant.value<QPixmap> ();
            if (!pix.isNull ()) {
                label.setPixmap (pix);
                label.setAlignment (Qt.AlignTop | Qt.AlignRight);
                label.setVisible (true);
            } else {
                string str = variant.toString ();
                if (!str.isEmpty ()) {
                    label.setText (str);
                    label.setTextFormat (Qt.RichText);
                    label.setVisible (true);
                    label.setOpenExternalLinks (true);
                }
            }
        }
    
        string titleTemplate () {
            return string.fromLatin1 (R" (<font color="%1" size="5">)").arg (Theme.instance ().wizardHeaderTitleColor ().name ()) + string.fromLatin1 ("%1</font>");
        }
    
        string subTitleTemplate () {
            return string.fromLatin1 ("<font color=\"%1\">").arg (Theme.instance ().wizardHeaderTitleColor ().name ()) + string.fromLatin1 ("%1</font>");
        }
    
        void initErrorLabel (QLabel *errorLabel) {
            string style = QLatin1String ("border : 1px solid #eed3d7; border-radius : 5px; padding : 3px;"
                                          "background-color : #f2dede; color : #b94a48;");
    
            errorLabel.setStyleSheet (style);
            errorLabel.setWordWrap (true);
            auto sizePolicy = errorLabel.sizePolicy ();
            sizePolicy.setRetainSizeWhenHidden (true);
            errorLabel.setSizePolicy (sizePolicy);
            errorLabel.setVisible (false);
        }
    
        void customizeHintLabel (QLabel *label) {
            auto palette = label.palette ();
            QColor textColor = palette.color (QPalette.Text);
            textColor.setAlpha (128);
            palette.setColor (QPalette.Text, textColor);
            label.setPalette (palette);
        }
    
    } // ns WizardCommon
    
    } // namespace Occ
    