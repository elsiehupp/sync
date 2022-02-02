/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Soup;

namespace Occ {

/***********************************************************
@brief The Format_warnings_wizard_page class
@ingroup gui
***********************************************************/
class Format_warnings_wizard_page : QWizard_page {

    protected string format_warnings (string[] warnings);
}



    string Format_warnings_wizard_page.format_warnings (string[] warnings) {
        string ret;
        if (warnings.count () == 1) {
            ret = _("<b>Warning:</b> %1").arg (warnings.first ());
        } else if (warnings.count () > 1) {
            ret = _("<b>Warning:</b>") + " <ul>";
            Q_FOREACH (string warning, warnings) {
                ret += string.from_latin1 ("<li>%1</li>").arg (warning);
            }
            ret += "</ul>";
        }

        return ret;
    }