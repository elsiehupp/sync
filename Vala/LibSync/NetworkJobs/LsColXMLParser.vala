/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

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
               GLib.HashMap<string, ExtraFolderInfo> *sizes,
               const string expected_path);

signals:
    void directory_listing_subfolders (string[] items);
    void directory_listing_iterated (string name, QMap<string, string> properties);
    void finished_with_error (QNetworkReply reply);
    void finished_without_error ();




    LsColXMLParser.LsColXMLParser () = default;

    bool LsColXMLParser.parse (GLib.ByteArray xml, GLib.HashMap<string, ExtraFolderInfo> *file_info, string expected_path) {
        // Parse DAV response
        QXmlStreamReader reader (xml);
        reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

        string[] folders;
        string current_href;
        QMap<string, string> current_tmp_properties;
        QMap<string, string> current_http200Properties;
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
                        GLib.warn (lc_ls_col_job) << "Invalid href" << href_string << "expected starting with" << expected_path;
                        return false;
                    }
                    current_href = href_string;
                } else if (name == QLatin1String ("response")) {
                } else if (name == QLatin1String ("propstat")) {
                    inside_propstat = true;
                } else if (name == QLatin1String ("status") && inside_propstat) {
                    string http_status = reader.read_element_text ();
                    if (http_status.starts_with ("HTTP/1.1 200")) {
                        current_props_have_http200 = true;
                    } else {
                        current_props_have_http200 = false;
                    }
                } else if (name == QLatin1String ("prop")) {
                    inside_prop = true;
                    continue;
                } else if (name == QLatin1String ("multistatus")) {
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
                        if (current_href.ends_with ('/')) {
                            current_href.chop (1);
                        }
                        /* emit */ directory_listing_iterated (current_href, current_http200Properties);
                        current_href.clear ();
                        current_http200Properties.clear ();
                    } else if (reader.name () == "propstat") {
                        inside_propstat = false;
                        if (current_props_have_http200) {
                            current_http200Properties = QMap<string, string> (current_tmp_properties);
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
            GLib.warn (lc_ls_col_job) << "ERROR" << reader.error_string () << xml;
            return false;
        } else if (!inside_multi_status) {
            GLib.warn (lc_ls_col_job) << "ERROR no WebDAV response?" << xml;
            return false;
        } else {
            /* emit */ directory_listing_subfolders (folders);
            /* emit */ finished_without_error ();
        }
        return true;
    }
};