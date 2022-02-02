/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>


namespace Occ {

/***********************************************************
@brief The HttpCredentialsGui namespace
@ingroup gui
***********************************************************/
namespace CredentialsFactory {

    AbstractCredentials create (string type) {
        // empty string might happen for old version of configuration
        if (type == "http" || type == "") {
            return new HttpCredentialsGui;
        } else if (type == "dummy") {
            return new DummyCredentials;
        } else if (type == "webflow") {
            return new WebFlowCredentials;
        } else {
            GLib.warn (lc_gui_credentials, "Unknown credentials type : %s", q_printable (type));
            return new DummyCredentials;
        }
    }

} // namespace CredentialsFactory

} // namespace Occ
