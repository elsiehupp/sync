/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

//  #include <Gtk.Application>

int main (int argc, char* argv[]) {
    Gtk.Application app = new Gtk.Application (argc, argv);
    HttpServer server;
    return app.exec ();
}
