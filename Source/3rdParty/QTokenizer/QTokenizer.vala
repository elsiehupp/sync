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

template <class T, class Const_iterator>
struct QTokenizerPrivate {
    using char_type = typename T.value_type;

    struct State {
        bool in_quote = false;
        bool in_escape = false;
        char_type quote_char = '\0';
    };

    QTokenizerPrivate (T& _string, T& _delims) :
        string (_string)
      , begin (string.begin ())
      , end (string.end ())
      , token_begin (end)
      , token_end (begin)
      , delimiters (_delims)
      , is_delim (false)
      , return_delimiters (false)
      , return_quotes (false) {
    }

    bool is_delimiter (char_type c) {
        return delimiters.contains (c);
    }

    bool is_quote (char_type c) {
        return quotes.contains (c);
    }

    // Returns true if a delimiter was not hit
    bool next_char (State* state, char_type c) {
        if (state.in_quote) {
            if (state.in_escape) {
                state.in_escape = false;
            } else if (c == '\\') {
                state.in_escape = true;
            } else if (c == state.quote_char) {
                state.in_quote = false;
            }
        } else {
            if (is_delimiter (c))
                return false;
            state.in_quote = is_quote (state.quote_char = c);
        }
        return true;
    }

    T string;
    // ### copies begin and end for performance, premature optimization?
    Const_iterator begin;
    Const_iterator end;
    Const_iterator token_begin;
    Const_iterator token_end;
    T delimiters;
    T quotes;
    bool is_delim;
    bool return_delimiters;
    bool return_quotes;
};

template <class T, class Const_iterator = typename T.Const_iterator>
class QTokenizer {

    public using char_type = typename T.value_type;

    /***********************************************************
       \class QTokenizer
       \inmodule Qt_network
       \brief QTokenizer tokenizes Strings on string, QByteArray,
              std.string or std.wstring

       Example Usage:

       \code
         string str = ...;
         QByte_array_tokenizer tokenizer (str, "; ");
         tokenizer.set_quote_characters ("\"'");
         tokenizer.set_return_delimiters (true);
         while (tokenizer.has_next ()) {
           QByteArray token = tokenizer.next ();
           bool is_delimiter = tokenizer.is_delimiter ();
           ...
         }
       \endcode

       \param string The string to tokenize
       \param delimiters A string containing delimiters

       \sa QStringTokenizer, QByte_array_tokenizer, String_tokenizer, WString_tokenizer
    ***********************************************************/
    public QTokenizer (T& string, T& delimiters)
        : d (new QTokenizerPrivate<T, Const_iterator> (string, delimiters)) { }

    /***********************************************************
       Whether or not to return delimiters as tokens
       \see set_quote_characters
    ***********************************************************/
    public void set_return_delimiters (bool enable) { d.return_delimiters = enable; }

    /***********************************************************
       Sets characters that are considered to start and end quotes.

       When between two characters considered a quote, delimiters will
       be ignored.

       When between quotes, blackslash characters will cause the QTokenizer
       to skip the next character.

       \param quotes Characters that delimit quotes.
    ***********************************************************/
    public void set_quote_characters (T& quotes) { d.quotes = quotes; }

    /***********************************************************
       Whether or not to return delimiters as tokens
       \see set_quote_characters
    ***********************************************************/
    public void set_return_quote_characters (bool enable) { d.return_quotes = enable; }

    /***********************************************************
       Retrieve next token.

       Returns true if there are more tokens, false otherwise.

       \sa next ()
    ***********************************************************/
    public bool has_next () {
        typename QTokenizerPrivate<T, Const_iterator>.State state;
        d.is_delim = false;
        for (;;) {
            d.token_begin = d.token_end;
            if (d.token_end == d.end)
                return false;
            d.token_end++;
            if (d.next_char (&state, *d.token_begin))
                break;
            if (d.return_delimiters) {
                d.is_delim = true;
                return true;
            }
        }
        while (d.token_end != d.end && d.next_char (&state, *d.token_end)) {
            d.token_end++;
        }
        return true;
    }

    /***********************************************************
       Resets the tokenizer to the starting position.
    ***********************************************************/
    public void reset () {
        d.token_end = d.begin;
    }

    /***********************************************************
       Returns true if the current token is a delimiter,
       if one more more delimiting characters have been set.
    ***********************************************************/
    public bool is_delimiter () { return d.is_delim; }

    /***********************************************************
       Returns the current token.

       Use \c has_next () to fetch the next token.
    ***********************************************************/
    public T next () {
        int len = std.distance (d.token_begin, d.token_end);
        Const_iterator tmp_start = d.token_begin;
        if (!d.return_quotes && len > 1 && d.is_quote (*d.token_begin)) {
            tmp_start++;
            len -= 2;
        }
        return T (tmp_start, len);
    }

private:
    friend class QStringTokenizer;
    QSharedPointer<QTokenizerPrivate<T, Const_iterator> > d;
};

class QStringTokenizer : QTokenizer<string> {

    public QStringTokenizer (string &string, string &delim) :
        QTokenizer<string, string.Const_iterator> (string, delim) {}
    /***********************************************************
    @brief Like \see next (), but returns a lightweight string reference
    @return A reference to the token within the string
    ***********************************************************/
    public QString_ref string_ref () {
        // If those differences overflow an int we'd have a veeeeeery long string in memory
        int begin = std.distance (d.begin, d.token_begin);
        int end = std.distance (d.token_begin, d.token_end);
        if (!d.return_quotes && d.is_quote (*d.token_begin)) {
            begin++;
            end -= 2;
        }
        return QString_ref (&d.string, begin, end);
    }
};

using QByte_array_tokenizer = QTokenizer<QByteArray>;
using String_tokenizer = QTokenizer<std.string>;
using WString_tokenizer = QTokenizer<std.wstring>;

QT_END_NAMESPACE

