/***********************************************************
@class TestTokenizer

@author 2014 Daniel Molkentin <daniel@molkentin.de>

This file is part of the Qt Library

@copyright LGPLv2.1 only

@copyright GPLv3.0 only
***********************************************************/
public class TestTokenizer : GLib.Object {

    const string SIMPLE = "A SIMPLE tokenizer test";
    const string GLib.UOTED = "\"Wait for me!\" he shouted";

    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_SIMPLE () {
        GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (SIMPLE, " ");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "A");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "SIMPLE");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "tokenizer");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "test");

        GLib.COMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_SIMPLE_ref () {
        GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (SIMPLE, " ");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.VERIFY (tokenizer.string_ref () == "A");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.VERIFY (tokenizer.string_ref () == "SIMPLE");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.VERIFY (tokenizer.string_ref () == "tokenizer");

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.VERIFY (tokenizer.string_ref () == "test");

        GLib.COMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_quoted () {
        const string multiquote = "\"'Billy - the Kid' is dead!\"";
        GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (multiquote, " -");
        tokenizer.set_quote_characters ("\"");
        tokenizer.set_return_quote_characters (true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "\"'Billy - the Kid' is dead!\"");

        GLib.COMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_skip_quotes () {
        const string multiquote = "\"'Billy - the Kid' is dead!\"";
        GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (multiquote, " ");
        tokenizer.set_quote_characters ("\"");
        tokenizer.set_return_quote_characters (false);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.next (), "'Billy - the Kid' is dead!");
        GLib.COMPARE (tokenizer.string_ref ().to_string (), "'Billy - the Kid' is dead!");

        GLib.COMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_with_delims () {
        const string delims = "I;Insist,On/a-Delimiter";
        GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (delims, ";,/-");
        tokenizer.set_return_delimiters (true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), false);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), false);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), false);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), false);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), true);

        GLib.COMPARE (tokenizer.has_next (), true);
        GLib.COMPARE (tokenizer.is_delimiter (), false);

        GLib.COMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_reset_tokenizer () {
        for (int i = 0; i < 2; i++) {
            GLib.StringTokenizer tokenizer = new GLib.StringTokenizer (SIMPLE, " ");

            GLib.COMPARE (tokenizer.has_next (), true);
            GLib.COMPARE (tokenizer.next (), "A");

            GLib.COMPARE (tokenizer.has_next (), true);
            GLib.COMPARE (tokenizer.next (), "SIMPLE");

            GLib.COMPARE (tokenizer.has_next (), true);
            GLib.COMPARE (tokenizer.next (), "tokenizer");

            GLib.COMPARE (tokenizer.has_next (), true);
            GLib.COMPARE (tokenizer.next (), "test");

            GLib.COMPARE (tokenizer.has_next (), false);

            tokenizer.on_reset ();
        }
    }

    // ### string, other types
}
