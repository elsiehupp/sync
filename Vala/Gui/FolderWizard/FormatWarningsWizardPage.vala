/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FormatWarningsWizardPage class
@ingroup gui
***********************************************************/
class FormatWarningsWizardPage : QWizardPage {

    protected string format_warnings (string[] warnings) {
        string ret;
        if (warnings.count () == 1) {
            ret = _("<b>Warning:</b> %1").arg (warnings.first ());
        } else if (warnings.count () > 1) {
            ret = _("<b>Warning:</b>") + " <ul>";
            foreach (string warning, warnings) {
                ret += string.from_latin1 ("<li>%1</li>").arg (warning);
            }
            ret += "</ul>";
        }

        return ret;
    }

} // class FormatWarningsWizardPage

} // namespace Ui
} // namespace Occ
