/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The HttpCredentialsGui namespace
@ingroup gui
***********************************************************/
public class CredentialsFactory {

    public static AbstractCredentials create (string type) {
        // empty string might happen for old version of configuration
        if (type == "http" || type == "") {
            return new HttpCredentialsGui ();
        } else if (type == "dummy") {
            return new DummyCredentials ();
        } else if (type == "webflow") {
            return new WebFlowCredentials ();
        } else {
            GLib.warning ("Did not recognize preferred credential type; defaulting to dummy credentials.");
            return new DummyCredentials ();
        }
    }

} // namespace CredentialsFactory

} // namespace Occ
