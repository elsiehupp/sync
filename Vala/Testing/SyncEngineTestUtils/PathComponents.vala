/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

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