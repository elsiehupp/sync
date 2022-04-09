namespace Occ {
namespace Testing {

/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv??? or later
***********************************************************/
int main (int argc, char* argv[]) {
    GLib.Application app = new GLib.Application (argc, argv);
    HttpServer server;
    return app.exec ();
}
