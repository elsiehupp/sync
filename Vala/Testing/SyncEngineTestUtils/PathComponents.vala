/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

public class PathComponents : GLib.Object {

    private string[] components;

    /***********************************************************
    ***********************************************************/
    public PathComponents.from_char (char path) {
        this.components = path.to_string ().split ("/", Qt.SkipEmptyParts);
    }


    /***********************************************************
    ***********************************************************/
    public PathComponents.from_string (string path) {
        this.components = path.split ("/", Qt.SkipEmptyParts);
    }


    /***********************************************************
    ***********************************************************/
    public PathComponents (string[] path_components) {
        this.components = path_components;
    }


    /***********************************************************
    ***********************************************************/
    public PathComponents parent_directory_components () {
        return new PathComponents (mid (0, size () - 1));
    }


    /***********************************************************
    ***********************************************************/
    public PathComponents sub_components () {
        return new PathComponents (mid (1));
    }


    /***********************************************************
    ***********************************************************/
    //  public PathComponents sub_components () {
    //      remove_first ();
    //      return std.move (*this);
    //  }


    /***********************************************************
    ***********************************************************/
    public string path_root () {
        return first ();
    }


    /***********************************************************
    ***********************************************************/
    public string filename () {
        return last ();
    }

} // class PathComponents
} // namespace Testing
