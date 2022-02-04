/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include
//  #include <GLib.List>
//  #include <QPair>

namespace Occ {

/***********************************************************
@brief The Notification_confirm_job class
@ingroup gui

Class to call an action-link of a notification coming from the server.
All the communication logic is handled in this class.

***********************************************************/
class Notification_confirm_job : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public Notification_confirm_job (AccountPointer account);


    /***********************************************************
    @brief Set the verb and link for the job

    @param verb currently supported GET PUT POST DELETE
    ***********************************************************/
    public void set_link_and_verb (GLib.Uri link, GLib.ByteArray verb);


    /***********************************************************
    @brief Start the OCS request
    ***********************************************************/
    public void on_start () override;

signals:

    /***********************************************************
    Result of the OCS request

    @param reply the reply
    ***********************************************************/
    void job_finished (string reply, int reply_code);


    /***********************************************************
    ***********************************************************/
    private bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.ByteArray this.verb;
    private GLib.Uri this.link;
}

    Notification_confirm_job.Notification_confirm_job (AccountPointer account)
        : base (account, "") {
        set_ignore_credential_failure (true);
    }

    void Notification_confirm_job.set_link_and_verb (GLib.Uri link, GLib.ByteArray verb) {
        this.link = link;
        this.verb = verb;
    }

    void Notification_confirm_job.on_start () {
        if (!this.link.is_valid ()) {
            GLib.warn (lc_notifications_job) << "Attempt to trigger invalid URL : " << this.link.to_string ();
            return;
        }
        QNetworkRequest req;
        req.set_raw_header ("Ocs-APIREQUEST", "true");
        req.set_raw_header ("Content-Type", "application/x-www-form-urlencoded");

        send_request (this.verb, this.link, req);

        AbstractNetworkJob.on_start ();
    }

    bool Notification_confirm_job.on_finished () {
        int reply_code = 0;
        // FIXME : check for the reply code!
        const string reply_str = reply ().read_all ();

        if (reply_str.contains ("<?xml version=\"1.0\"?>")) {
            const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
            const var rex_match = rex.match (reply_str);
            if (rex_match.has_match ()) {
                // this is a error message coming back from ocs.
                reply_code = rex_match.captured (1).to_int ();
            }
        }
        /* emit */ job_finished (reply_str, reply_code);

        return true;
    }
    }
    