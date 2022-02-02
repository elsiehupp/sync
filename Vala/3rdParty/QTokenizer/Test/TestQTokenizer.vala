// #include <Qt_test>

namespace {
    const string simple = "A simple tokenizer test";
    const string quoted = "\"Wait for me!\" he shouted";
}

class TestTokenizer : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_tokenize_q_string_simple () {
        QStringTokenizer tokenizer = new QStringTokenizer (simple, " ");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "A");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "simple");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "tokenizer");

        QCOMPARE (tokenizer.has_next (), true);
        QCOMPARE (tokenizer.next (), "test");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void tokenize_q_string_simple_ref () {
        QStringTokenizer tokenizer = new QStringTokenizer (simple, " ");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "A");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "simple");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "tokenizer");

        QCOMPARE (tokenizer.has_next (), true);
        QVERIFY (tokenizer.string_ref () == "test");

        QCOMPARE (tokenizer.has_next (), false);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void tokenize_q_string_quoted () {
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
    private on_ void tokenize_q_string_skip_quotes () {
        const string multiquote ("\"'Billy - the Kid' is dead!\"");
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
    private on_ void tokenize_q_string_with_delims () {
        const string delims ("I;Insist,On/a-Delimiter");
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
    private on_ void reset_tokenizer () {
        for (int i = 0; i < 2; i++) {
            QStringTokenizer tokenizer = new QStringTokenizer (simple, " ");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "A");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "simple");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "tokenizer");

            QCOMPARE (tokenizer.has_next (), true);
            QCOMPARE (tokenizer.next (), "test");

            QCOMPARE (tokenizer.has_next (), false);

            tokenizer.on_reset ();
        }
    }

    // ### GLib.ByteArray, other types
};

QTEST_APPLESS_MAIN (TestTokenizer)

