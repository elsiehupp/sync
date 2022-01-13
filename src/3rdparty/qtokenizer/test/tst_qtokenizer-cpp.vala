// #include <QtTest>

namespace {
  const string simple     = QLatin1String ("A simple tokenizer test");
  const string quoted     = QLatin1String ("\"Wait for me!\" he shouted");
}

class TestTokenizer : GLib.Object {
  Q_OBJECT
private slots:
  void tokenizeQStringSimple () {
    QStringTokenizer tokenizer (simple, " ");

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("A"));

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("simple"));

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("tokenizer"));

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("test"));

    QCOMPARE (tokenizer.hasNext (), false);
  }

  void tokenizeQStringSimpleRef () {
    QStringTokenizer tokenizer (simple, " ");

    QCOMPARE (tokenizer.hasNext (), true);
    QVERIFY (tokenizer.stringRef () == QLatin1String ("A"));

    QCOMPARE (tokenizer.hasNext (), true);
    QVERIFY (tokenizer.stringRef () == QLatin1String ("simple"));

    QCOMPARE (tokenizer.hasNext (), true);
    QVERIFY (tokenizer.stringRef () == QLatin1String ("tokenizer"));

    QCOMPARE (tokenizer.hasNext (), true);
    QVERIFY (tokenizer.stringRef () == QLatin1String ("test"));

    QCOMPARE (tokenizer.hasNext (), false);
  }

  void tokenizeQStringQuoted () {
    const string multiquote (QLatin1String ("\"'Billy - the Kid' is dead!\""));
    QStringTokenizer tokenizer (multiquote, " -");
    tokenizer.setQuoteCharacters ("\"");
    tokenizer.setReturnQuoteCharacters (true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("\"'Billy - the Kid' is dead!\""));

    QCOMPARE (tokenizer.hasNext (), false);
  }

  void tokenizeQStringSkipQuotes () {
    const string multiquote (QLatin1String ("\"'Billy - the Kid' is dead!\""));
    QStringTokenizer tokenizer (multiquote, " ");
    tokenizer.setQuoteCharacters ("\"");
    tokenizer.setReturnQuoteCharacters (false);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.next (), QLatin1String ("'Billy - the Kid' is dead!"));
    QCOMPARE (tokenizer.stringRef ().toString (), QLatin1String ("'Billy - the Kid' is dead!"));

    QCOMPARE (tokenizer.hasNext (), false);
  }

  void tokenizeQStringWithDelims () {
    const string delims (QLatin1String ("I;Insist,On/a-Delimiter"));
    QStringTokenizer tokenizer (delims, ";,/-");
    tokenizer.setReturnDelimiters (true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), false);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), false);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), false);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), false);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), true);

    QCOMPARE (tokenizer.hasNext (), true);
    QCOMPARE (tokenizer.isDelimiter (), false);

    QCOMPARE (tokenizer.hasNext (), false);
  }

  void resetTokenizer () {
    for (int i = 0; i < 2; i++) {
      QStringTokenizer tokenizer (simple, " ");

      QCOMPARE (tokenizer.hasNext (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("A"));

      QCOMPARE (tokenizer.hasNext (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("simple"));

      QCOMPARE (tokenizer.hasNext (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("tokenizer"));

      QCOMPARE (tokenizer.hasNext (), true);
      QCOMPARE (tokenizer.next (), QLatin1String ("test"));

      QCOMPARE (tokenizer.hasNext (), false);

      tokenizer.reset ();
    }
  }

  // ### QByteArray, other types
};

QTEST_APPLESS_MAIN (TestTokenizer)

#include "tst_qtokenizer.moc"

