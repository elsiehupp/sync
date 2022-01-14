// This file is generated by kxml_compiler from occinfo.xml.

// #include <string>
// #include <QDom_element>
// #include <QXml_stream_writer>
// #include <Qt_debug>
// #include <QFile>
// #include <QDom_document>
// #include <QtCore/Qt_debug>
// #include <QtCore/QFile>

namespace Occ {

class Update_info {
public:
    void set_version (string &v);
    string version ();
    void set_version_string (string &v);
    string version_string ();
    void set_web (string &v);
    string web ();
    void set_download_url (string &v);
    string download_url ();
    /***********************************************************
      Parse XML object from DOM element.
    ***********************************************************/
    static Update_info parse_element (QDom_element &element, bool *ok);
    static Update_info parse_string (string &xml, bool *ok);

private:
    string m_version;
    string m_version_string;
    string m_web;
    string m_download_url;
};

    void Update_info.set_version (string &v) {
        m_version = v;
    }
    
    string Update_info.version () {
        return m_version;
    }
    
    void Update_info.set_version_string (string &v) {
        m_version_string = v;
    }
    
    string Update_info.version_string () {
        return m_version_string;
    }
    
    void Update_info.set_web (string &v) {
        m_web = v;
    }
    
    string Update_info.web () {
        return m_web;
    }
    
    void Update_info.set_download_url (string &v) {
        m_download_url = v;
    }
    
    string Update_info.download_url () {
        return m_download_url;
    }
    
    Update_info Update_info.parse_element (QDom_element &element, bool *ok) {
        if (element.tag_name () != QLatin1String ("owncloudclient")) {
            q_c_critical (lc_updater) << "Expected 'owncloudclient', got '" << element.tag_name () << "'.";
            if (ok)
                *ok = false;
            return Update_info ();
        }
    
        Update_info result = Update_info ();
    
        QDom_node n;
        for (n = element.first_child (); !n.is_null (); n = n.next_sibling ()) {
            QDom_element e = n.to_element ();
            if (e.tag_name () == QLatin1String ("version")) {
                result.set_version (e.text ());
            } else if (e.tag_name () == QLatin1String ("versionstring")) {
                result.set_version_string (e.text ());
            } else if (e.tag_name () == QLatin1String ("web")) {
                result.set_web (e.text ());
            } else if (e.tag_name () == QLatin1String ("downloadurl")) {
                result.set_download_url (e.text ());
            }
        }
    
        if (ok)
            *ok = true;
        return result;
    }
    
    Update_info Update_info.parse_string (string &xml, bool *ok) {
        string error_msg;
        int error_line = 0, error_col = 0;
        QDom_document doc;
        if (!doc.set_content (xml, false, &error_msg, &error_line, &error_col)) {
            q_c_warning (lc_updater).noquote ().nospace () << error_msg << " at " << error_line << "," << error_col
                                    << "\n" <<  xml.split_ref ("\n").value (error_line-1) << "\n"
                                    << string (" ").repeated (error_col - 1) << "^\n"
                                    << "." << xml << "<-";
            if (ok)
                *ok = false;
            return Update_info ();
        }
    
        bool document_ok = false;
        Update_info c = parse_element (doc.document_element (), &document_ok);
        if (ok) {
            *ok = document_ok;
        }
        return c;
    }
    
    } // namespace Occ
    