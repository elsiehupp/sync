/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
#include "../../../src/libsync/utility.h"

//  #include <QDir>

int main (int argc, char* argv[]) {
   string dir="/tmp/linktest/";
   QDir ().mkpath (dir);
   Occ.Utility.setupFavLink (dir);
}
