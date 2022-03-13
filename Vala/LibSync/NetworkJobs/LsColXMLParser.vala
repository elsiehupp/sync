/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The LsColJob class
@ingroup libsync
***********************************************************/
class LsColXMLParser : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public LsColXMLParser ();

    /***********************************************************
    ***********************************************************/
    public bool parse (GLib.ByteArray xml,
        GLib.HashTable<string, ExtraFolderInfo> *sizes,
        string expected_path);


    signal void directory_listing_subfolders (string[] items);
    signal void directory_listing_iterated (string name, GLib.HashTable<string, string> properties);
    signal void finished_with_error (Soup.Reply reply);
    signal void finished_without_error ();




    //  LsColXMLParser.LsColXMLParser () = default;

    bool LsColXMLParser.parse (GLib.ByteArray xml, GLib.HashTable<string, ExtraFolderInfo> *file_info, string expected_path) {
        // Parse DAV response
        QXmlStreamReader reader = new QXmlStreamReader (xml);
        reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

        string[] folders;
        string current_href;
        GLib.HashTable<string, string> current_tmp_properties;
        GLib.HashTable<string, string> current_http200Properties;
        bool current_props_have_http200 = false;
        bool inside_propstat = false;
        bool inside_prop = false;
        bool inside_multi_status = false;

        while (!reader.at_end ()) {
            QXmlStreamReader.TokenType type = reader.read_next ();
            string name = reader.name ().to_string ();
            // Start elements with DAV:
            if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == QLatin1String ("DAV:")) {
                if (name == QLatin1String ("href")) {
                    // We don't use URL encoding in our request URL (which is the expected path) (QNAM will do it for us)
                    // but the result will have URL encoding..
                    string href_string = GLib.Uri.from_local_file (GLib.Uri.from_percent_encoding (reader.read_element_text ().to_utf8 ()))
                            .adjusted (GLib.Uri.NormalizePathSegments)
                            .path ();
                    if (!href_string.starts_with (expected_path)) {
                        GLib.warning ("Invalid href " + href_string + " expected starting with " + expected_path);
                        return false;
                    }
                    current_href = href_string;
                } else if (name == "response") {
                } else if (name == "propstat") {
                    inside_propstat = true;
                } else if (name == "status" && inside_propstat) {
                    string http_status = reader.read_element_text ();
                    if (http_status.starts_with ("HTTP/1.1 200")) {
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

            if (type == QXmlStreamReader.StartElement && inside_propstat && inside_prop) {
                // All those elements are properties
                string property_content = read_contents_as_string (reader);
                if (name == QLatin1String ("resourcetype") && property_content.contains ("collection")) {
                    folders.append (current_href);
                } else if (name == QLatin1String ("size")) {
                    bool ok = false;
                    var s = property_content.to_long_long (&ok);
                    if (ok && file_info) {
                        (*file_info)[current_href].size = s;
                    }
                } else if (name == QLatin1String ("fileid")) {
                    (*file_info)[current_href].file_identifier = property_content.to_utf8 ();
                }
                current_tmp_properties.insert (reader.name ().to_string (), property_content);
            }

            // End elements with DAV:
            if (type == QXmlStreamReader.EndElement) {
                if (reader.namespace_uri () == QLatin1String ("DAV:")) {
                    if (reader.name () == "response") {
                        if (current_href.has_suffix ('/')) {
                            current_href.chop (1);
                        }
                        /* emit */ directory_listing_iterated (current_href, current_http200Properties);
                        current_href.clear ();
                        current_http200Properties.clear ();
                    } else if (reader.name () == "propstat") {
                        inside_propstat = false;
                        if (current_props_have_http200) {
                            current_http200Properties = GLib.HashTable<string, string> (current_tmp_properties);
                        }
                        current_tmp_properties.clear ();
                        current_props_have_http200 = false;
                    } else if (reader.name () == "prop") {
                        inside_prop = false;
                    }
                }
            }
        }

        if (reader.has_error ()) {
            // XML Parser error? Whatever had been emitted before will come as directory_listing_iterated
            GLib.warning ("ERROR " + reader.error_string () + xml);
            return false;
        } else if (!inside_multi_status) {
            GLib.warning ("ERROR no WebDAV response? " + xml.to_string ());
            return false;
        } else {
            /* emit */ directory_listing_subfolders (folders);
            /* emit */ finished_without_error ();
        }
        return true;
    }


    /***********************************************************
    supposed to read <D:collection> when pointing to
    <D:resourcetype><D:collection></D:resourcetype>..
    ***********************************************************/
    private static string read_contents_as_string (QXmlStreamReader reader) {
        string result;
        int level = 0;
        do {
            QXmlStreamReader.TokenType type = reader.read_next ();
            if (type == QXmlStreamReader.StartElement) {
                level++;
                result += "<" + reader.name ().to_string () + ">";
            } else if (type == QXmlStreamReader.Characters) {
                result += reader.text ();
            } else if (type == QXmlStreamReader.EndElement) {
                level--;
                if (level < 0) {
                    break;
                }
                result += "</" + reader.name ().to_string () + ">";
            }

        } while (!reader.at_end ());
        return result;
    }

} // class LsColXMLParser

} // namespace LibSync
} // namespace Occ
