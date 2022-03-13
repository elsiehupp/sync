/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

public class PathComponents : string[] {

    /***********************************************************
    ***********************************************************/
    public PathComponents (char path) {
        PathComponents (path.to_string ());
    }

    /***********************************************************
    ***********************************************************/
    public PathComponents (string path) {
        string[] { path.split ('/', Qt.SkipEmptyParts) }
    }

    /***********************************************************
    ***********************************************************/
    public PathComponents (string[] path_components) {
        string[] { path_components }
    }

    /***********************************************************
    ***********************************************************/
    public PathComponents parent_directory_components () {
        return PathComponents ( mid (0, size () - 1));
    }


    /***********************************************************
    ***********************************************************/
    public PathComponents sub_components () & {
        return new PathComponents ( mid (1));
    }

    /***********************************************************
    ***********************************************************/
    public PathComponents sub_components () && {
        remove_first ();
        return std.move (*this);
    }

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
