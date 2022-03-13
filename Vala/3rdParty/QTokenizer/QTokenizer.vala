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



QT_BEGIN_NAMESPACE

template <class T, class ConstIterator>
struct QTokenizerPrivate {
    using CharType = typename T.value_type;

    struct State {
        bool in_quote = false;
        bool in_escape = false;
        CharType quote_char = '\0';
    }

    QTokenizerPrivate (T& this.string, T& this.delims) :
        string (this.string)
      , begin (string.begin ())
      , end (string.end ())
      , token_begin (end)
      , token_end (begin)
      , delimiters (this.delims)
      , is_delim (false)
      , return_delimiters (false)
      , return_quotes (false) {
    }

    bool is_delimiter (CharType c) {
        return delimiters.contains (c);
    }

    bool is_quote (CharType c) {
        return quotes.contains (c);
    }

    // Returns true if a delimiter was not hit
    bool next_char (State* state, CharType c) {
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
    ConstIterator begin;
    ConstIterator end;
    ConstIterator token_begin;
    ConstIterator token_end;
    T delimiters;
    T quotes;
    bool is_delim;
    bool return_delimiters;
    bool return_quotes;
}

template <class T, class ConstIterator = typename T.ConstIterator>
public class QTokenizer {

    /***********************************************************
    ***********************************************************/
    public CharType : typename T.value_type;


    /***********************************************************
    \class QTokenizer
    \inmodule QtNetwork
    \brief QTokenizer tokenizes Strings on string, GLib.ByteArray,
            std.string or std.wstring

    Example Usage:

    \code
        string string_value = ...;
        QByte_array_tokenizer tokenizer (string_value, "; ");
        tokenizer.set_quote_characters ("\"'");
        tokenizer.set_return_delimiters (true);
        while (tokenizer.has_next ()) {
        GLib.ByteArray token = tokenizer.next ();
        bool is_delimiter = tokenizer.is_delimiter ();
        ...
        }
    \endcode

    \param string The string to tokenize
    \param delimiters A string containing delimiters

    \sa QStringTokenizer, QByte_array_tokenizer, String_tokenizer, WString_tokenizer
    ***********************************************************/
    public QTokenizer (T& string, T& delimiters)
        : d (new QTokenizerPrivate<T, ConstIterator> (string, delimiters)) {}


    /***********************************************************
    Whether or not to return delimiters as tokens
    \see set_quote_characters
    ***********************************************************/
    public void set_return_delimiters (bool enable) {
        d.return_delimiters = enable;
    }


    /***********************************************************
    Sets characters that are considered to on_start and end quotes.

    When between two characters considered a quote, delimiters will
    be ignored.

    When between quotes, blackslash characters will cause the QTokenizer
    to skip the next character.

    \param quotes Characters that delimit quotes.
    ***********************************************************/
    public void set_quote_characters (T& quotes) {
        d.quotes = quotes;
    }


    /***********************************************************
    Whether or not to return delimiters as tokens
    \see set_quote_characters
    ***********************************************************/
    public void set_return_quote_characters (bool enable) {
        d.return_quotes = enable;
    }


    /***********************************************************
    Retrieve next token.

    Returns true if there are more tokens, false otherwise.

    \sa next ()
    ***********************************************************/
    public bool has_next () {
        typename QTokenizerPrivate<T, ConstIterator>.State state;
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
    public void on_reset () {
        d.token_end = d.begin;
    }


    /***********************************************************
    Returns true if the current token is a delimiter,
    if one more more delimiting characters have been set.
    ***********************************************************/
    public bool is_delimiter () {
        return d.is_delim;
    }


    /***********************************************************
    Returns the current token.

    Use \c has_next () to fetch the next token.
    ***********************************************************/
    public T next () {
        int len = std.distance (d.token_begin, d.token_end);
        ConstIterator tmp_start = d.token_begin;
        if (!d.return_quotes && len > 1 && d.is_quote (*d.token_begin)) {
            tmp_start++;
            len -= 2;
        }
        return T (tmp_start, len);
    }


    /***********************************************************
    ***********************************************************/
    private friend class QStringTokenizer;
    private unowned<QTokenizerPrivate<T, ConstIterator> > d;
}


using QByte_array_tokenizer = QTokenizer<GLib.ByteArray>;
using String_tokenizer = QTokenizer<std.string>;
using WString_tokenizer = QTokenizer<std.wstring>;

QT_END_NAMESPACE

