/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

using Occ;

namespace Testing {

int numDirs = 0;
int numFiles = 0;

//  template<int filesPerDir, int dirPerDir, int maxDepth>
void addBunchOfFiles (int depth, string path, FileModifier file_info) {
    for (int fileNum = 1; fileNum <= filesPerDir; ++fileNum) {
        string name = "file" + string.number (fileNum);
        file_info.insert (path.isEmpty () ? name : path + "/" + name);
        numFiles++;
    }
    if (depth >= maxDepth)
        return;
    for (int dirNum = 1; dirNum <= dirPerDir; ++dirNum) {
        string name = "directory" + string.number (dirNum);
        string subPath = path.isEmpty () ? name : path + "/" + name;
        file_info.mkdir (subPath);
        numDirs++;
        addBunchOfFiles<filesPerDir, dirPerDir, maxDepth> (depth + 1, subPath, file_info);
    }
}

int main (int argc, char argv[]) {
    QCoreApplication app = new QCoreApplication (argc, argv);
    FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //  addBunchOfFiles<10, 8, 4> (0, "", fake_folder.local_modifier ());

    GLib.debug ("NUMFILES " + numFiles);
    GLib.debug ("NUMDIRS " + numDirs);
    QElapsedTimer timer;
    timer.on_signal_start ();
    bool result1 = fake_folder.sync_once ();
    GLib.debug ("FIRST SYNC : " + result1 + timer.restart ());
    bool result2 = fake_folder.sync_once ();
    GLib.debug ("SECOND SYNC : " + result2 + timer.restart ());
    return (result1 && result2) ? 0 : -1;
}
