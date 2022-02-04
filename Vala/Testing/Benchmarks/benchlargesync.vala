/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

using namespace Occ;

int numDirs = 0;
int numFiles = 0;

template<int filesPerDir, int dirPerDir, int maxDepth>
void addBunchOfFiles (int depth, string path, FileModifier fi) {
    for (int fileNum = 1; fileNum <= filesPerDir; ++fileNum) {
        string name = QStringLiteral ("file") + string.number (fileNum);
        fi.insert (path.isEmpty () ? name : path + "/" + name);
        numFiles++;
    }
    if (depth >= maxDepth)
        return;
    for (int dirNum = 1; dirNum <= dirPerDir; ++dirNum) {
        string name = QStringLiteral ("dir") + string.number (dirNum);
        string subPath = path.isEmpty () ? name : path + "/" + name;
        fi.mkdir (subPath);
        numDirs++;
        addBunchOfFiles<filesPerDir, dirPerDir, maxDepth> (depth + 1, subPath, fi);
    }
}

int main (int argc, char argv[]) {
    QCoreApplication app (argc, argv);
    FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
    addBunchOfFiles<10, 8, 4> (0, "", fakeFolder.localModifier ());

    qDebug () << "NUMFILES" << numFiles;
    qDebug () << "NUMDIRS" << numDirs;
    QElapsedTimer timer;
    timer.on_start ();
    bool result1 = fakeFolder.syncOnce ();
    qDebug () << "FIRST SYNC : " << result1 << timer.restart ();
    bool result2 = fakeFolder.syncOnce ();
    qDebug () << "SECOND SYNC : " << result2 << timer.restart ();
    return (result1 && result2) ? 0 : -1;
}
