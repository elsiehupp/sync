namespace Occ {
namespace LibSync {

/***********************************************************
@class Account

@brief The Account class represents an account on an
ownCloud Server

The Account has a name and url. It also has information
about credentials, SSL errors and certificates.

@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
/***********************************************************
@brief Reimplement this to handle SSL errors from libsync
@ingroup libsync
***********************************************************/
public abstract class AbstractSslErrorHandler { //: GLib.Object {
//    public abstract bool handle_errors (GLib.List<GnuTLS.ErrorCode> error_list, GLib.SslConfiguration conf, GLib.List<GLib.TlsCertificate> cert_list, Account account);

} // class AbstractSslErrorHandler

} // namespace LibSync
} // namespace Occ
