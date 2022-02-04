/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class DirectEditor : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private string identifier;

    /***********************************************************
    ***********************************************************/
    private GLib.List<GLib.ByteArray> mime_types;

    /***********************************************************
    ***********************************************************/
    private GLib.List<GLib.ByteArray> optional_mime_types;

    /***********************************************************
    ***********************************************************/
    public DirectEditor (string identifier, string name, GLib.Object parent = new GLib.Object ())
        base (parent);
        this.identifier = identifier;
        this.name = name;
    }


    /***********************************************************
    ***********************************************************/
    public string name () {
        return this.name;
    }


    /***********************************************************
    ***********************************************************/
    public void add_mimetype (GLib.ByteArray mime_type) {
        this.mime_types.append (mime_type);
    }


    /***********************************************************
    ***********************************************************/
    public void add_optional_mimetype (GLib.ByteArray mime_type) {
        this.optional_mime_types.append (mime_type);
    }


    /***********************************************************
    ***********************************************************/
    public string identifier () {
        return this.identifier;
    }


    /***********************************************************
    ***********************************************************/
    public bool has_mimetype (QMimeType mime_type) {
        return this.mime_types.contains (mime_type.name ().to_latin1 ());
    }


    /***********************************************************
    ***********************************************************/
    public bool has_optional_mimetype (QMimeType mime_type) {
        return this.optional_mime_types.contains (mime_type.name ().to_latin1 ());
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.ByteArray> mime_types () {
        return this.mime_types;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.ByteArray> optional_mime_types () {
        return this.optional_mime_types;
    }
}
