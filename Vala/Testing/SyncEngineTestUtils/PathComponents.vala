/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class PathComponents : string[] {

    /***********************************************************
    ***********************************************************/
    public PathComponents (char path) {
        PathComponents (string.fromUtf8 (path));
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
    public PathComponents parentDirComponents () {
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
    public string pathRoot () {
        return first ();
    }

    /***********************************************************
    ***********************************************************/
    public string filename () {
        return last ();
    }

} // class PathComponents
} // namespace Testing
