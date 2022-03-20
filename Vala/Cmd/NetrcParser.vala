namespace Occ {
namespace Cmd {

/***********************************************************
@class NetrcParser

@brief Parser for netrc files

@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class NetrcParser : GLib.Object {

    const string DEFAULT_KEYWORD = "default";
    const string MACHINE_KEYWORD = "machine";
    const string LOGIN_KEYWORD = "login";
    const string PASSWORD_KEYWORD = "password";

    private GLib.HashTable<string, QPair<string, string>> entries;
    private QPair<string, string> default_pair;
    private string netrc_location;


    /***********************************************************
    ***********************************************************/
    public NetrcParser (string file = "") {
        this.netrc_location = file;
        if (this.netrc_location == "") {
            this.netrc_location = GLib.Dir.home_path + "/.netrc";
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool parse () {
        GLib.File netrc = new GLib.File (this.netrc_location);
        if (!netrc.open (QIODevice.ReadOnly)) {
            return false;
        }
        string content = netrc.read_all ();

        QStringTokenizer tokenizer = new QStringTokenizer (content, " \n\t");
        tokenizer.quote_characters ("\"'");

        QPair<string, string> pair;
        string machine;
        bool is_default = false;
        while (tokenizer.has_next ()) {
            string key = tokenizer.next ();
            if (key == DEFAULT_KEYWORD) {
                try_add_entry_and_clear (machine, pair, is_default);
                is_default = true;
                continue; // don't read a value
            }

            if (!tokenizer.has_next ()) {
                GLib.debug ("Error fetching value for " + key);
                return false;
            }
            string value = tokenizer.next ();

            if (key == MACHINE_KEYWORD) {
                try_add_entry_and_clear (machine, pair, is_default);
                machine = value;
            } else if (key == LOGIN_KEYWORD) {
                pair.first = value;
            } else if (key == PASSWORD_KEYWORD) {
                pair.second = value;
            } // ignore unsupported tokens
        }
        try_add_entry_and_clear (machine, pair, is_default);

        if (!this.entries == "" || this.default_pair != q_make_pair ("", "")) {
            return true;
        } else {
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public QPair<string, string> find (string machine) {
        if (this.entries.contains (machine)) {
            return this.entries.get (machine);
        } else {
            return this.default_pair;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void try_add_entry_and_clear (string machine, QPair<string, string> pair, bool is_default) {
        if (is_default) {
            this.default_pair = pair;
        } else if (!machine == "" && !pair.first == "") {
            this.entries.insert (machine, pair);
        }
        pair = q_make_pair ("", "");
        machine.clear ();
        is_default = false;
    }

} // class NetrcParser

} // namespace Cmd
} // namespace Occ
