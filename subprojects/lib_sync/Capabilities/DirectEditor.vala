namespace Occ {
namespace LibSync {

/***********************************************************
@class DirectEditor

@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/
public class DirectEditor { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    string identifier { public get; private set; }

    /***********************************************************
    ***********************************************************/
    GLib.List<string> mime_types { public get; private set; }

    /***********************************************************
    ***********************************************************/
    GLib.List<string> optional_mime_types { public get; private set; }

    /***********************************************************
    ***********************************************************/
    string name { public get; private set; }

    /***********************************************************
    ***********************************************************/
    public DirectEditor (string identifier, string name) {
        //  base ();
        //  this.identifier = identifier;
        //  this.name = name;
    }


    /***********************************************************
    ***********************************************************/
    public void add_mimetype (string mime_type) {
        //  this.mime_types.append (mime_type);
    }


    /***********************************************************
    ***********************************************************/
    public void add_optional_mimetype (string mime_type) {
        //  this.optional_mime_types.append (mime_type);
    }


    /***********************************************************
    ***********************************************************/
    public bool has_mimetype (GLib.MimeType mime_type) {
        //  return this.mime_types.contains (mime_type.name ().to_latin1 ());
    }


    /***********************************************************
    ***********************************************************/
    public bool has_optional_mimetype (GLib.MimeType mime_type) {
        //  return this.optional_mime_types.contains (mime_type.name ().to_latin1 ());
    }

} // class DirectEditor

} // namespace LibSync
} // namespace Occ
