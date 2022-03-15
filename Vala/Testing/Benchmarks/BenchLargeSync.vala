/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

using Occ;

namespace Testing {

int number_of_directories = 0;
int number_of_files = 0;

//  template<int files_per_directory, int directories_per_directory, int max_depth>
void add_a_bunch_of_files (int depth, string path, FileModifier file_info) {
    for (int file_number = 1; file_number <= files_per_directory; ++file_number) {
        string name = "file" + file_number.to_string ();
        file_info.insert (path == "" ? name : path + "/" + name);
        number_of_files++;
    }
    if (depth >= max_depth)
        return;
    for (int directory_number = 1; directory_number <= directories_per_directory; ++directory_number) {
        string name = "directory" + directory_number.to_string ();
        string sub_path = path == "" ? name : path + "/" + name;
        file_info.mkdir (sub_path);
        number_of_directories++;
        add_a_bunch_of_files<files_per_directory, directories_per_directory, max_depth> (depth + 1, sub_path, file_info);
    }
}

int main (int argc, char argv[]) {
    QCoreApplication app = new QCoreApplication (argc, argv);
    FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
    //  add_a_bunch_of_files<10, 8, 4> (0, "", fake_folder.local_modifier ());

    GLib.debug ("NUMFILES " + number_of_files);
    GLib.debug ("NUMDIRS " + number_of_directories);
    QElapsedTimer timer;
    timer.on_signal_start ();
    bool result1 = fake_folder.sync_once ();
    GLib.debug ("FIRST SYNC: " + result1 + timer.restart ());
    bool result2 = fake_folder.sync_once ();
    GLib.debug ("SECOND SYNC: " + result2 + timer.restart ());
    return (result1 && result2) ? 0 : -1;
}
