/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief The HttpCredentialsGui namespace
@ingroup gui
***********************************************************/
namespace CredentialsFactory {

    AbstractCredentials *create (string &type);

} // ns CredentialsFactory

} // namespace Occ

#endif








/***********************************************************
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <string>

namespace Occ {

    Q_LOGGING_CATEGORY (lcGuiCredentials, "nextcloud.gui.credentials", QtInfoMsg)
    
    namespace CredentialsFactory {
    
        AbstractCredentials *create (string &type) {
            // empty string might happen for old version of configuration
            if (type == "http" || type == "") {
                return new HttpCredentialsGui;
            } else if (type == "dummy") {
                return new DummyCredentials;
            } else if (type == "webflow") {
                return new WebFlowCredentials;
            } else {
                qCWarning (lcGuiCredentials, "Unknown credentials type : %s", qPrintable (type));
                return new DummyCredentials;
            }
        }
    
    } // ns CredentialsFactory
    
    } // namespace Occ
    