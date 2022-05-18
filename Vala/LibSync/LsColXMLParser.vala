namespace Occ {
namespace LibSync {

/***********************************************************
@class LscolXMLParser

@brief The LscolJob class

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class LscolXMLParser : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public LscolXMLParser ();

    /***********************************************************
    ***********************************************************/
    public bool parse (string xml,
        GLib.HashTable<string, ExtraFolderInfo> *sizes,
        string expected_path);


    internal signal void signal_directory_listing_subfolders (GLib.List<string> items);
    internal signal void signal_directory_listing_iterated (string name, GLib.HashTable<string, string> properties);
    internal signal void signal_finished_with_error (GLib.InputStream reply);
    internal signal void signal_finished_without_error ();




    //  LscolXMLParser.LscolXMLParser () = default;

    bool LscolXMLParser.parse (string xml, GLib.HashTable<string, ExtraFolderInfo> *file_info, string expected_path) {
        // Parse DAV response
        GLib.XmlStreamReader reader = new GLib.XmlStreamReader (xml);
        reader.add_extra_namespace_declaration (GLib.XmlStreamNamespaceDeclaration ("d", "DAV:"));

        GLib.List<string> folders = new GLib.List<string> ();
        string current_href;
        GLib.HashTable<string, string> current_temporary_properties;
        GLib.HashTable<string, string> current_http200Properties;
        bool current_props_have_http200 = false;
        bool inside_propstat = false;
        bool inside_prop = false;
        bool inside_multi_status = false;

        while (!reader.at_end ()) {
            GLib.XmlStreamReader.TokenType type = reader.read_next ();
            string name = reader.name ().to_string ();
            // Start elements with DAV:
            if (type == GLib.XmlStreamReader.StartElement && reader.namespace_uri () == "DAV:") {
                if (name == "href") {
                    // We don't use URL encoding in our request URL (which is the expected path) (Soup.Session will do it for us)
                    // but the result will have URL encoding..
                    string href_string = GLib.Uri.from_local_file (GLib.Uri.from_percent_encoding (reader.read_element_text ().to_utf8 ()))
                            .adjusted (GLib.Uri.NormalizePathSegments)
                            .path;
                    if (!href_string.has_prefix (expected_path)) {
                        GLib.warning ("Invalid href " + href_string + " expected starting with " + expected_path);
                        return false;
                    }
                    current_href = href_string;
                } else if (name == "response") {
                } else if (name == "propstat") {
                    inside_propstat = true;
                } else if (name == "status" && inside_propstat) {
                    string http_status = reader.read_element_text ();
                    if (http_status.has_prefix ("HTTP/1.1 200")) {
                        current_props_have_http200 = true;
                    } else {
                        current_props_have_http200 = false;
                    }
                } else if (name == "prop") {
                    inside_prop = true;
                    continue;
                } else if (name == "multistatus") {
                    inside_multi_status = true;
                    continue;
                }
            }

            if (type == GLib.XmlStreamReader.StartElement && inside_propstat && inside_prop) {
                // All those elements are properties
                string property_content = read_contents_as_string (reader);
                if (name == "resourcetype" && property_content.contains ("collection")) {
                    folders.append (current_href);
                } else if (name == "size") {
                    bool ok = false;
                    var s = property_content.to_long_long (&ok);
                    if (ok && file_info) {
                        (*file_info)[current_href].size = s;
                    }
                } else if (name == "fileid") {
                    (*file_info)[current_href].file_identifier = property_content.to_utf8 ();
                }
                current_temporary_properties.insert (reader.name ().to_string (), property_content);
            }

            // End elements with DAV:
            if (type == GLib.XmlStreamReader.EndElement) {
                if (reader.namespace_uri () == "DAV:") {
                    if (reader.name () == "response") {
                        if (current_href.has_suffix ("/")) {
                            current_href.chop (1);
                        }
                        signal_directory_listing_iterated (current_href, current_http200Properties);
                        current_href == "";
                        current_http200Properties == "";
                    } else if (reader.name () == "propstat") {
                        inside_propstat = false;
                        if (current_props_have_http200) {
                            current_http200Properties = new GLib.HashTable<string, string> (current_temporary_properties);
                        }
                        current_temporary_properties == "";
                        current_props_have_http200 = false;
                    } else if (reader.name () == "prop") {
                        inside_prop = false;
                    }
                }
            }
        }

        if (reader.has_error ()) {
            // XML Parser error? Whatever had been emitted before will come as signal_directory_listing_iterated
            GLib.warning ("ERROR " + reader.error_string + xml);
            return false;
        } else if (!inside_multi_status) {
            GLib.warning ("ERROR no WebDAV response? " + xml.to_string ());
            return false;
        } else {
            signal_directory_listing_subfolders (folders);
            signal_finished_without_error ();
        }
        return true;
    }


    /***********************************************************
    supposed to read <D:collection> when pointing to
    <D:resourcetype><D:collection></D:resourcetype>..
    ***********************************************************/
    private static string read_contents_as_string (GLib.XmlStreamReader reader) {
        string result;
        int level = 0;
        do {
            GLib.XmlStreamReader.TokenType type = reader.read_next ();
            if (type == GLib.XmlStreamReader.StartElement) {
                level++;
                result += "<" + reader.name ().to_string () + ">";
            } else if (type == GLib.XmlStreamReader.Characters) {
                result += reader.text ();
            } else if (type == GLib.XmlStreamReader.EndElement) {
                level--;
                if (level < 0) {
                    break;
                }
                result += "</" + reader.name ().to_string () + ">";
            }

        } while (!reader.at_end ());
        return result;
    }

} // class LscolXMLParser

} // namespace LibSync
} // namespace Occ
