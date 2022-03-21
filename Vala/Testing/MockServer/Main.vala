namespace Occ {
namespace Testing {

/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv??? or later
***********************************************************/
int main (int argc, char* argv[]) {
    Gtk.Application app = new Gtk.Application (argc, argv);
    HttpServer server;
    return app.exec ();
}
