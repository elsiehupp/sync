/***********************************************************
@class TestTokenizer

@author 2014 Daniel Molkentin <daniel@molkentin.de>

This file is part of the Qt Library

@copyright LGPLv2.1 only

@copyright GPLv3.0 only
***********************************************************/
public class TestTokenizer : GLib.Object {

    const string SIMPLE = "A SIMPLE tokenizer test";
    const string QUOTED = "\"Wait for me!\" he shouted";

    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_SIMPLE () {
        QStringTokenizer tokenizer = new QStringTokenizer (SIMPLE, " ");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "A");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "SIMPLE");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "tokenizer");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "test");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_SIMPLE_ref () {
        QStringTokenizer tokenizer = new QStringTokenizer (SIMPLE, " ");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "A");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "SIMPLE");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "tokenizer");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "test");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_quoted () {
        const string multiquote = "\"'Billy - the Kid' is dead!\"";
        QStringTokenizer tokenizer = new QStringTokenizer (multiquote, " -");
        tokenizer.set_quote_characters ("\"");
        tokenizer.set_return_quote_characters (true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "\"'Billy - the Kid' is dead!\"");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_skip_quotes () {
        const string multiquote = "\"'Billy - the Kid' is dead!\"";
        QStringTokenizer tokenizer = new QStringTokenizer (multiquote, " ");
        tokenizer.set_quote_characters ("\"");
        tokenizer.set_return_quote_characters (false);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "'Billy - the Kid' is dead!");
        QCOMPARE (tokenizer.string_ref ().to_string (), "'Billy - the Kid' is dead!");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_with_delims () {
        const string delims = "I;Insist,On/a-Delimiter";
        QStringTokenizer tokenizer = new QStringTokenizer (delims, ";,/-");
        tokenizer.set_return_delimiters (true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), false);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), false);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), false);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), false);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), true);

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.is_delimiter (), false);

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_reset_tokenizer () {
        for (int i = 0; i < 2; i++) {
            QStringTokenizer tokenizer = new QStringTokenizer (SIMPLE, " ");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "A");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "SIMPLE");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "tokenizer");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "test");

            QCOMPARE (tokenizer.has_next (), false);

            tokenizer.on_reset ();
        }
    }

    // ### string, other types
}
