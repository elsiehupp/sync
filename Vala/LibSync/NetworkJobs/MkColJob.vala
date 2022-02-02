/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The MkColJob class
@ingroup libsync
***********************************************************/
class MkColJob : AbstractNetworkJob {
    GLib.Uri this.url; // Only used if the constructor taking a url is taken.
    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> this.extra_headers;


    /***********************************************************
    ***********************************************************/
    public MkColJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public MkColJob (AccountPointer account, GLib.Uri url,);

    /***********************************************************
    ***********************************************************/
    public 
    public st GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent = new GLib.Object ());


    public void on_start () override;

signals:
    void finished_with_error (Soup.Reply reply);
    void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    private bool on_finished () override;







    MkColJob.MkColJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    MkColJob.MkColJob (AccountPointer account, string path, GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent)
        , this.extra_headers (extra_headers) {
    }

    MkColJob.MkColJob (AccountPointer account, GLib.Uri url,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> extra_headers, GLib.Object parent)
        : AbstractNetworkJob (account, "", parent)
        , this.url (url)
        , this.extra_headers (extra_headers) {
    }

    void MkColJob.on_start () {
        // add 'Content-Length : 0' header (see https://github.com/owncloud/client/issues/3256)
        Soup.Request req;
        req.set_raw_header ("Content-Length", "0");
        for (var it = this.extra_headers.const_begin (); it != this.extra_headers.const_end (); ++it) {
            req.set_raw_header (it.key (), it.value ());
        }

        // assumes ownership
        if (this.url.is_valid ()) {
            send_request ("MKCOL", this.url, req);
        } else {
            send_request ("MKCOL", make_dav_url (path ()), req);
        }
        AbstractNetworkJob.on_start ();
    }

    bool MkColJob.on_finished () {
        q_c_info (lc_mk_col_job) << "MKCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                        << reply_status_"";

        if (reply ().error () != Soup.Reply.NoError) {
            Q_EMIT finished_with_error (reply ());
        } else {
            Q_EMIT finished_without_error ();
        }
        return true;
    }

    /****************************************************************************/
    // supposed to read <D:collection> when pointing to <D:resourcetype><D:collection></D:resourcetype>..
    static string read_contents_as_string (QXmlStreamReader reader) {
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
};