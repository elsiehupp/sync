/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QPair>
//  #include <QDir>
//  #include <QTextStream>
//  #include <qtokenizer.h>

//  #include <QDebug>

namespace Occ {

/***********************************************************
@brief Parser for netrc files
@ingroup cmd
***********************************************************/
public class NetrcParser {

    /***********************************************************
    ***********************************************************/
    public LoginPair : QPair<string, string> { }

    /***********************************************************
    ***********************************************************/
    public NetrcParser (string file = "");

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public LoginPair find (string machine);


    /***********************************************************
    ***********************************************************/
    private void try_add_entry_and_clear (string machine, LoginPair pair, bool is_default);
    private GLib.HashMap<string, LoginPair> this.entries;
    private LoginPair this.default;
    private string this.netrc_location;
}



    namespace {
        string default_keyword = "default";
        string machine_keyword = "machine";
        string login_keyword = "login";
        string password_keyword = "password";
    }

    NetrcParser.NetrcParser (string file) {
        this.netrc_location = file;
        if (this.netrc_location.is_empty ()) {
            this.netrc_location = QDir.home_path () + "/.netrc";
        }
    }

    void NetrcParser.try_add_entry_and_clear (string machine, LoginPair pair, bool is_default) {
        if (is_default) {
            this.default = pair;
        } else if (!machine.is_empty () && !pair.first.is_empty ()) {
            this.entries.insert (machine, pair);
        }
        pair = q_make_pair ("", "");
        machine.clear ();
        is_default = false;
    }

    bool NetrcParser.parse () {
        GLib.File netrc (this.netrc_location);
        if (!netrc.open (QIODevice.ReadOnly)) {
            return false;
        }
        string content = netrc.read_all ();

        QStringTokenizer tokenizer = new QStringTokenizer (content, " \n\t");
        tokenizer.quote_characters ("\"'");

        LoginPair pair;
        string machine;
        bool is_default = false;
        while (tokenizer.has_next ()) {
            string key = tokenizer.next ();
            if (key == default_keyword) {
                try_add_entry_and_clear (machine, pair, is_default);
                is_default = true;
                continue; // don't read a value
            }

            if (!tokenizer.has_next ()) {
                GLib.debug ("error fetching value for" + key;
                return false;
            }
            string value = tokenizer.next ();

            if (key == machine_keyword) {
                try_add_entry_and_clear (machine, pair, is_default);
                machine = value;
            } else if (key == login_keyword) {
                pair.first = value;
            } else if (key == password_keyword) {
                pair.second = value;
            } // ignore unsupported tokens
        }
        try_add_entry_and_clear (machine, pair, is_default);

        if (!this.entries.is_empty () || this.default != q_make_pair ("", "")) {
            return true;
        } else {
            return false;
        }
    }

    NetrcParser.LoginPair NetrcParser.find (string machine) {
        GLib.HashMap<string, LoginPair>.ConstIterator it = this.entries.find (machine);
        if (it != this.entries.end ()) {
            return it;
        } else {
            return this.default;
        }
    }

    } // namespace Occ
    