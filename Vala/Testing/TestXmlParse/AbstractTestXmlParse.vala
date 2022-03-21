namespace Occ {
namespace Testing {

/***********************************************************
@class 

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public abstract class AbstractTestXmlParse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    protected bool success;
    protected string[] subdirectories;
    protected string[] items;


    /***********************************************************
    ***********************************************************/
    protected void on_signal_directory_listing_sub_folders (string[] list) {
        GLib.debug ("subfolders: " + list.join ("/n"));
        this.subdirectories.append (list);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_directory_listing_iterated (string item, GLib.HashTable<string,string> map) {
        GLib.debug ("     item: " + item);
        this.items.append (item);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_finished_successfully () {
        this.success = true;
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_init () {
        GLib.debug (Q_FUNC_INFO);
        this.success = false;
        delete (this.subdirectories);
        delete (this.items);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_cleanup () {}

} // class TestXmlParse

} // namespace Testing
} // namespace Occ
