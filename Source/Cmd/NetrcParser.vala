/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QHash>
// #include <QPair>
// #include <QDir>
// #include <GLib.File>
// #include <QTextStream>

// #include <qtokenizer.h>

// #include <QDebug>

namespace Occ {

/***********************************************************
@brief Parser for netrc files
@ingroup cmd
***********************************************************/
class NetrcParser {

    public using Login_pair = QPair<string, string>;

    public NetrcParser (string file = string ());


    public bool parse ();


    public Login_pair find (string machine);


    private void try_add_entry_and_clear (string machine, Login_pair &pair, bool &is_default);
    private QHash<string, Login_pair> _entries;
    private Login_pair _default;
    private string _netrc_location;
};



    namespace {
        string default_keyword = QLatin1String ("default");
        string machine_keyword = QLatin1String ("machine");
        string login_keyword = QLatin1String ("login");
        string password_keyword = QLatin1String ("password");
    }

    NetrcParser.NetrcParser (string file) {
        _netrc_location = file;
        if (_netrc_location.is_empty ()) {
            _netrc_location = QDir.home_path () + QLatin1String ("/.netrc");
        }
    }

    void NetrcParser.try_add_entry_and_clear (string machine, Login_pair &pair, bool &is_default) {
        if (is_default) {
            _default = pair;
        } else if (!machine.is_empty () && !pair.first.is_empty ()) {
            _entries.insert (machine, pair);
        }
        pair = q_make_pair (string (), string ());
        machine.clear ();
        is_default = false;
    }

    bool NetrcParser.parse () {
        GLib.File netrc (_netrc_location);
        if (!netrc.open (QIODevice.ReadOnly)) {
            return false;
        }
        string content = netrc.read_all ();

        QStringTokenizer tokenizer = new QStringTokenizer (content, " \n\t");
        tokenizer.set_quote_characters ("\"'");

        Login_pair pair;
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
                q_debug () << "error fetching value for" << key;
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

        if (!_entries.is_empty () || _default != q_make_pair (string (), string ())) {
            return true;
        } else {
            return false;
        }
    }

    NetrcParser.Login_pair NetrcParser.find (string machine) {
        QHash<string, Login_pair>.Const_iterator it = _entries.find (machine);
        if (it != _entries.end ()) {
            return it;
        } else {
            return _default;
        }
    }

    } // namespace Occ
    