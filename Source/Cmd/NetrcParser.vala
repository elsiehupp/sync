/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QHash>
// #include <QPair>
// #include <QDir>
// #include <QFile>
// #include <QTextStream>

// #include <qtokenizer.h>

// #include <QDebug>

namespace Occ {

/***********************************************************
@brief Parser for netrc files
@ingroup cmd
***********************************************************/
class NetrcParser {
public:
    using LoginPair = QPair<string, string>;

    NetrcParser (string &file = string ());
    bool parse ();
    LoginPair find (string &machine);

private:
    void tryAddEntryAndClear (string &machine, LoginPair &pair, bool &isDefault);
    QHash<string, LoginPair> _entries;
    LoginPair _default;
    string _netrcLocation;
};



    namespace {
        string defaultKeyword = QLatin1String ("default");
        string machineKeyword = QLatin1String ("machine");
        string loginKeyword = QLatin1String ("login");
        string passwordKeyword = QLatin1String ("password");
    }
    
    NetrcParser.NetrcParser (string &file) {
        _netrcLocation = file;
        if (_netrcLocation.isEmpty ()) {
            _netrcLocation = QDir.homePath () + QLatin1String ("/.netrc");
        }
    }
    
    void NetrcParser.tryAddEntryAndClear (string &machine, LoginPair &pair, bool &isDefault) {
        if (isDefault) {
            _default = pair;
        } else if (!machine.isEmpty () && !pair.first.isEmpty ()) {
            _entries.insert (machine, pair);
        }
        pair = qMakePair (string (), string ());
        machine.clear ();
        isDefault = false;
    }
    
    bool NetrcParser.parse () {
        QFile netrc (_netrcLocation);
        if (!netrc.open (QIODevice.ReadOnly)) {
            return false;
        }
        string content = netrc.readAll ();
    
        QStringTokenizer tokenizer (content, " \n\t");
        tokenizer.setQuoteCharacters ("\"'");
    
        LoginPair pair;
        string machine;
        bool isDefault = false;
        while (tokenizer.hasNext ()) {
            string key = tokenizer.next ();
            if (key == defaultKeyword) {
                tryAddEntryAndClear (machine, pair, isDefault);
                isDefault = true;
                continue; // don't read a value
            }
    
            if (!tokenizer.hasNext ()) {
                qDebug () << "error fetching value for" << key;
                return false;
            }
            string value = tokenizer.next ();
    
            if (key == machineKeyword) {
                tryAddEntryAndClear (machine, pair, isDefault);
                machine = value;
            } else if (key == loginKeyword) {
                pair.first = value;
            } else if (key == passwordKeyword) {
                pair.second = value;
            } // ignore unsupported tokens
        }
        tryAddEntryAndClear (machine, pair, isDefault);
    
        if (!_entries.isEmpty () || _default != qMakePair (string (), string ())) {
            return true;
        } else {
            return false;
        }
    }
    
    NetrcParser.LoginPair NetrcParser.find (string &machine) {
        QHash<string, LoginPair>.const_iterator it = _entries.find (machine);
        if (it != _entries.end ()) {
            return *it;
        } else {
            return _default;
        }
    }
    
    } // namespace Occ
    