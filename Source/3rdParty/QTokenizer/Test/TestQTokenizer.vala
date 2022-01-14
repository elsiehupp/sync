// #include <Qt_test>

namespace {
  const string simple     = QLatin1String ("A simple tokenizer test");
  const string quoted     = QLatin1String ("\"Wait for me!\" he shouted");
}

class TestTokenizer : GLib.Object {
  Q_OBJECT
private slots:
  void tokenize_q_string_simple () {
    QStringTokenizer tokenizer (simple, " ");

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("A"));

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("simple"));

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("tokenizer"));

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("test"));

    QCOMPARE (tokenizer.has_next (), false);
  }

  void tokenize_q_string_simple_ref () {
    QStringTokenizer tokenizer (simple, " ");

    QCOMPARE (tokenizer.has_next (), true);
    QVERIFY (tokenizer.string_ref () == QLatin1String ("A"));

    QCOMPARE (tokenizer.has_next (), true);
    QVERIFY (tokenizer.string_ref () == QLatin1String ("simple"));

    QCOMPARE (tokenizer.has_next (), true);
    QVERIFY (tokenizer.string_ref () == QLatin1String ("tokenizer"));

    QCOMPARE (tokenizer.has_next (), true);
    QVERIFY (tokenizer.string_ref () == QLatin1String ("test"));

    QCOMPARE (tokenizer.has_next (), false);
  }

  void tokenize_q_string_quoted () {
    const string multiquote (QLatin1String ("\"'Billy - the Kid' is dead!\""));
    QStringTokenizer tokenizer (multiquote, " -");
    tokenizer.set_quote_characters ("\"");
    tokenizer.set_return_quote_characters (true);

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("\"'Billy - the Kid' is dead!\""));

    QCOMPARE (tokenizer.has_next (), false);
  }

  void tokenize_q_string_skip_quotes () {
    const string multiquote (QLatin1String ("\"'Billy - the Kid' is dead!\""));
    QStringTokenizer tokenizer (multiquote, " ");
    tokenizer.set_quote_characters ("\"");
    tokenizer.set_return_quote_characters (false);

    QCOMPARE (tokenizer.has_next (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("'Billy - the Kid' is dead!"));
    QCOMPARE (tokenizer.string_ref ().to_string (), QLatin1String ("'Billy - the Kid' is dead!"));

    QCOMPARE (tokenizer.has_next (), false);
  }

  void tokenize_q_string_with_delims () {
    const string delims (QLatin1String ("I;Insist,On/a-Delimiter"));
    QStringTokenizer tokenizer (delims, ";,/-");
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

  void reset_tokenizer () {
    for (int i = 0; i < 2; i++) {
      QStringTokenizer tokenizer (simple, " ");

      QCOMPARE (tokenizer.has_next (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("A"));

      QCOMPARE (tokenizer.has_next (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("simple"));

      QCOMPARE (tokenizer.has_next (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("tokenizer"));

      QCOMPARE (tokenizer.has_next (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("test"));

      QCOMPARE (tokenizer.has_next (), false);

      tokenizer.reset ();
    }
  }

  // ### QByteArray, other types
};

QTEST_APPLESS_MAIN (TestTokenizer)

#include "tst_qtokenizer.moc"

