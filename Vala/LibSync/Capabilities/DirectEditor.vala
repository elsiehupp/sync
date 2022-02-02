/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

class DirectEditor : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public DirectEditor (string id, string name, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public void add_mimetype (GLib.ByteArray mime_type);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool has_optio

    /***********************************************************
    ***********************************************************/
    public string id ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public GLib.List<GLib.ByteArray> mime_types ();


    public GLib.List<GLib.ByteArray> optional_mime_types ();


    /***********************************************************
    ***********************************************************/
    private string this.id;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.List<GLib.ByteArray> this.mime_types;
    private GLib.List<GLib.ByteArray> this.optional_mime_types;
}



    DirectEditor.DirectEditor (string id, string name, GLib.Object parent)
        : GLib.Object (parent)
        , this.id (id)
        , this.name (name) {
    }

    string DirectEditor.id () {
        return this.id;
    }

    string DirectEditor.name () {
        return this.name;
    }

    void DirectEditor.add_mimetype (GLib.ByteArray mime_type) {
        this.mime_types.append (mime_type);
    }

    void DirectEditor.add_optional_mimetype (GLib.ByteArray mime_type) {
        this.optional_mime_types.append (mime_type);
    }

    GLib.List<GLib.ByteArray> DirectEditor.mime_types () {
        return this.mime_types;
    }

    GLib.List<GLib.ByteArray> DirectEditor.optional_mime_types () {
        return this.optional_mime_types;
    }

    bool DirectEditor.has_mimetype (QMimeType mime_type) {
        return this.mime_types.contains (mime_type.name ().to_latin1 ());
    }

    bool DirectEditor.has_optional_mimetype (QMimeType mime_type) {
        return this.optional_mime_types.contains (mime_type.name ().to_latin1 ());
    }