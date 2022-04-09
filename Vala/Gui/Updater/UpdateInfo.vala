// This file is generated by kxml_compiler from occinfo.xml.

//  #include <GLib.DomElement>
//  #include <GLib.Xml_stream_writer>
//  #include <Qt_debug>
//  #include <GLib.DomDocument>
//  #include <QtCore/Qt_debug>
//  #include <QtCore/GLib.File>

namespace Occ {
namespace Ui {

public class UpdateInfo : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public string version;
    public string version_string;
    public string web;
    public string download_url;
    public bool ok = false;


    /***********************************************************
    Parse XML object from DOM element.
    ***********************************************************/
    public UpdateInfo.parse_element (GLib.DomElement element) {
        if (element.tag_name () != "owncloudclient") {
            GLib.critical ("Expected 'owncloudclient', got '" + element.tag_name () + "'.");
            if (this.ok) {
                this.ok = false;
            }
            return UpdateInfo ();
        }

        //  UpdateInfo this = UpdateInfo ();

        GLib.DomNode n;
        for (n = element.first_child (); n != null; n = n.next_sibling ()) {
            GLib.DomElement child_element = n.to_element ();
            if (child_element.tag_name () == "version") {
                this.version = child_element.text ();
            } else if (child_element.tag_name () == "versionstring") {
                this.version_string = child_element.text ();
            } else if (child_element.tag_name () == "web") {
                this.web = child_element.text ();
            } else if (child_element.tag_name () == "downloadurl") {
                this.download_url = child_element.text ();
            }
        }

        if (this.ok) {
            this.ok = true;
        }
        return this;
    }


    /***********************************************************
    Parse XML object from DOM element.
    ***********************************************************/
    public UpdateInfo.parse_string (string xml, bool ok) {
        string error_msg;
        int error_line = 0;
        int error_col = 0;
        GLib.DomDocument doc;
        if (!doc.content (xml, false, error_msg, error_line, error_col)) {
            GLib.warning (error_msg + " at " + error_line.to_string () + "," + error_col.to_string ()
                + "\n" +  xml.split_ref ("\n").value (error_line - 1) + "\n"
                + " ".repeated (error_col - 1) + "^\n"
                + "." + xml + "<-");
            if (this.ok) {
                this.ok = false;
            }
            return;
        }

        new UpdateInfo.parse_element (doc.document_element ());
    }

} // class UpdateInfo

} // namespace Ui
} // namespace Occ
