/***********************************************************
Copyright (C) 2014 Daniel Molkentin <daniel@molkentin.de>
Contact : http://www.qt-project.org/legal

This file is part of th

$QT_BEGIN_LICENSE:LGPL$
Commercial License Usage
Licensees holding valid commercial Qt licenses may use this file in
accordance with the commercial license agreement provided with the
Software or, alternatively, in accordance with the terms contained in
a written agreement between you and Digia.  For licensing 
conditions see http://qt.digia.com/lice
use the contact form at http://qt.digia.com/contact-us.

GNU Lesser General Public License Usage
Alternatively, this file may be used under the terms of the GNU Les
General Public License version 2.1 as published by the Free Software
Foundation and appearing in the file LICENSE.LGPL included in the
packaging of this file.  Please review the following information to
ensure the GNU Lesser General Public License version 2.1 requireme
will be met : http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.

In addition, as a special exception, Digia gives you certain ad
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this pac

GNU General Public License Usage
Alternatively, this file may be used under the terms of the GNU
General Public License version 3.0 as published by the Free Software
Foundation and appearing in the file LICENSE.GPL included in the
packaging of this file.  Please review the following information to
ensure the GNU General Public License version 3.0 requirements will be
met : http://www.gnu.org/copyleft/gpl.html.


$QT_END_LICENSE$
****************************************************************************/

// #include <string>
// #include <QByteArray>
// #include <QSharedPointer>

QT_BEGIN_NAMESPACE

template <class T, class const_iterator>
struct QTokenizerPrivate {
    using char_type = typename T.value_type;

    struct State {
        bool inQuote = false;
        bool inEscape = false;
        char_type quoteChar = '\0';
    };

    QTokenizerPrivate (T& _string, T& _delims) :
        string (_string)
      , begin (string.begin ())
      , end (string.end ())
      , tokenBegin (end)
      , tokenEnd (begin)
      , delimiters (_delims)
      , isDelim (false)
      , returnDelimiters (false)
      , returnQuotes (false) {
    }

    bool isDelimiter (char_type c) {
        return delimiters.contains (c);
    }

    bool isQuote (char_type c) {
        return quotes.contains (c);
    }

    // Returns true if a delimiter was not hit
    bool nextChar (State* state, char_type c) {
        if (state.inQuote) {
            if (state.inEscape) {
                state.inEscape = false;
            } else if (c == '\\') {
                state.inEscape = true;
            } else if (c == state.quoteChar) {
                state.inQuote = false;
            }
        } else {
            if (isDelimiter (c))
                return false;
            state.inQuote = isQuote (state.quoteChar = c);
        }
        return true;
    }

    T string;
    // ### copies begin and end for performance, premature optimization?
    const_iterator begin;
    const_iterator end;
    const_iterator tokenBegin;
    const_iterator tokenEnd;
    T delimiters;
    T quotes;
    bool isDelim;
    bool returnDelimiters;
    bool returnQuotes;
};

template <class T, class const_iterator = typename T.const_iterator>
class QTokenizer {

    public using char_type = typename T.value_type;

    /***********************************************************
       \class QTokenizer
       \inmodule QtNetwork
       \brief QTokenizer tokenizes Strings on string, QByteArray,
              std.string or std.wstring

       Example Usage:

       \code
         string str = ...;
         QByteArrayTokenizer tokenizer (str, "; ");
         tokenizer.setQuoteCharacters ("\"'");
         tokenizer.setReturnDelimiters (true);
         while (tokenizer.hasNext ()) {
           QByteArray token = tokenizer.next ();
           bool isDelimiter = tokenizer.isDelimiter ();
           ...
         }
       \endcode

       \param string The string to tokenize
       \param delimiters A string containing delimiters

       \sa QStringTokenizer, QByteArrayTokenizer, StringTokenizer, WStringTokenizer
    ***********************************************************/
    public QTokenizer (T& string, T& delimiters)
        : d (new QTokenizerPrivate<T, const_iterator> (string, delimiters)) { }

    /***********************************************************
       Whether or not to return delimiters as tokens
       \see setQuoteCharacters
    ***********************************************************/
    public void setReturnDelimiters (bool enable) { d.returnDelimiters = enable; }

    /***********************************************************
       Sets characters that are considered to start and end quotes.

       When between two characters considered a quote, delimiters will
       be ignored.

       When between quotes, blackslash characters will cause the QTokenizer
       to skip the next character.

       \param quotes Characters that delimit quotes.
    ***********************************************************/
    public void setQuoteCharacters (T& quotes) { d.quotes = quotes; }

    /***********************************************************
       Whether or not to return delimiters as tokens
       \see setQuoteCharacters
    ***********************************************************/
    public void setReturnQuoteCharacters (bool enable) { d.returnQuotes = enable; }

    /***********************************************************
       Retrieve next token.

       Returns true if there are more tokens, false otherwise.

       \sa next ()
    ***********************************************************/
    public bool hasNext () {
        typename QTokenizerPrivate<T, const_iterator>.State state;
        d.isDelim = false;
        for (;;) {
            d.tokenBegin = d.tokenEnd;
            if (d.tokenEnd == d.end)
                return false;
            d.tokenEnd++;
            if (d.nextChar (&state, *d.tokenBegin))
                break;
            if (d.returnDelimiters) {
                d.isDelim = true;
                return true;
            }
        }
        while (d.tokenEnd != d.end && d.nextChar (&state, *d.tokenEnd)) {
            d.tokenEnd++;
        }
        return true;
    }

    /***********************************************************
       Resets the tokenizer to the starting position.
    ***********************************************************/
    public void reset () {
        d.tokenEnd = d.begin;
    }

    /***********************************************************
       Returns true if the current token is a delimiter,
       if one more more delimiting characters have been set.
    ***********************************************************/
    public bool isDelimiter () { return d.isDelim; }

    /***********************************************************
       Returns the current token.

       Use \c hasNext () to fetch the next token.
    ***********************************************************/
    public T next () {
        int len = std.distance (d.tokenBegin, d.tokenEnd);
        const_iterator tmpStart = d.tokenBegin;
        if (!d.returnQuotes && len > 1 && d.isQuote (*d.tokenBegin)) {
            tmpStart++;
            len -= 2;
        }
        return T (tmpStart, len);
    }

private:
    friend class QStringTokenizer;
    QSharedPointer<QTokenizerPrivate<T, const_iterator> > d;
};

class QStringTokenizer : QTokenizer<string> {

    public QStringTokenizer (string &string, string &delim) :
        QTokenizer<string, string.const_iterator> (string, delim) {}
    /***********************************************************
    @brief Like \see next (), but returns a lightweight string reference
    @return A reference to the token within the string
    ***********************************************************/
    public QStringRef stringRef () {
        // If those differences overflow an int we'd have a veeeeeery long string in memory
        int begin = std.distance (d.begin, d.tokenBegin);
        int end = std.distance (d.tokenBegin, d.tokenEnd);
        if (!d.returnQuotes && d.isQuote (*d.tokenBegin)) {
            begin++;
            end -= 2;
        }
        return QStringRef (&d.string, begin, end);
    }
};

using QByteArrayTokenizer = QTokenizer<QByteArray>;
using StringTokenizer = QTokenizer<std.string>;
using WStringTokenizer = QTokenizer<std.wstring>;

QT_END_NAMESPACE

