/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Testing {

class PathComponents : string[] {

    /***********************************************************
    ***********************************************************/
    public PathComponents (char path);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public PathComponents (string[] pathComponent

    /***********************************************************
    ***********************************************************/
    public PathComponents parentDirComponents ();


    public PathComponents subComponents () &;
    public PathComponents subComponents () && { removeFirst (); return std.move (*this); }
    public string pathRoot () { return first (); }
    public string fileName () { return last (); }
};





PathComponents.PathComponents (char path)
    : PathComponents ( string.fromUtf8 (path) } {
}

PathComponents.PathComponents (string path)
    : string[] { path.split ('/', Qt.SkipEmptyParts) } {
}

PathComponents.PathComponents (string[] pathComponents)
    : string[] { pathComponents } {
}

PathComponents PathComponents.parentDirComponents () {
    return PathComponents ( mid (0, size () - 1));
}

PathComponents PathComponents.subComponents () & {
    return PathComponents ( mid (1));
}