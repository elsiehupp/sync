/***********************************************************
@class GLib.TokenizerPrivate

@author 2014 Daniel Molkentin <daniel@molkentin.de>

This file is part of the Qt Library

@copyright LGPLv2.1 only

@copyright GPLv3.0 only
****************************************************************************/
public class GLib.TokenizerPrivate<T> : GLib.Object {

    //  template <class T, class ConstIterator>
    //  using GLib.Byte_array_tokenizer = GLib.Tokenizer<string>;
    //  using String_tokenizer = GLib.Tokenizer<std.string_value>;
    //  using WString_tokenizer = GLib.Tokenizer<std.wstring>;
    //  using CharType = typename T.value_type;

    public T string_value;
    // ### copies begin and end for performance, premature optimization?
    public ConstIterator begin;
    public ConstIterator end;
    public ConstIterator token_begin;
    public ConstIterator token_end;
    public T delimiters;
    public T quotes;
    public bool is_delim;
    public bool return_delimiters;
    public bool return_quotes;

    public class State : GLib.Object {
        public bool in_quote = false;
        public bool in_escape = false;
        public CharType quote_char = '\0';
    }

    public GLib.TokenizerPrivate (T string_value, T delimiters) {
        this.string_value = string_value;
        this.begin = string_value.begin ();
        this.end = string_value.end ();
        this.token_begin = end;
        this.token_end = begin;
        this.delimiters = delimiters;
        this.is_delim = false;
        this.return_delimiters = false;
        this.return_quotes = false;
    }


    public bool is_delimiter (CharType c) {
        return delimiters.contains (c);
    }


    public bool is_quote (CharType c) {
        return quotes.contains (c);
    }


    // Returns true if a delimiter was not hit
    public bool next_char (State* state, CharType c) {
        if (state.in_quote) {
            if (state.in_escape) {
                state.in_escape = false;
            } else if (c == '\\') {
                state.in_escape = true;
            } else if (c == state.quote_char) {
                state.in_quote = false;
            }
        } else {
            if (is_delimiter (c)) {
                return false;
            }
            state.in_quote = is_quote (state.quote_char = c);
        }
        return true;
    }

}

//  template <class T, class ConstIterator = typename T.ConstIterator>
public class GLib.Tokenizer<T> : GLib.Object {

    /***********************************************************
    ***********************************************************/
    //  public CharType : typename T.value_type;

    /***********************************************************
    ***********************************************************/
    //  private friend class GLib.StringTokenizer;
    internal unowned GLib.TokenizerPrivate<T, ConstIterator> tokenizer_private;


    /***********************************************************
    \class GLib.Tokenizer
    \inmodule QtNetwork
    \brief GLib.Tokenizer tokenizes Strings on string_value, string,
            std.string_value or std.wstring

    Example Usage:

    \code
        string_value string_value = ...;
        GLib.Byte_array_tokenizer tokenizer (string_value, "; ");
        tokenizer.set_quote_characters ("\"'");
        tokenizer.set_return_delimiters (true);
        while (tokenizer.has_next ()) {
        string token = tokenizer.next ();
        bool is_delimiter = tokenizer.is_delimiter ();
        ...
        }
    \endcode

    \param string_value The string_value to tokenize
    \param delimiters A string_value containing delimiters

    \sa GLib.StringTokenizer, GLib.Byte_array_tokenizer, String_tokenizer, WString_tokenizer
    ***********************************************************/
    public GLib.Tokenizer (T string_value, T delimiters) {
        this.tokenizer_private = new GLib.TokenizerPrivate<T, ConstIterator> (string_value, delimiters);
    }


    /***********************************************************
    Whether or not to return delimiters as tokens
    \see set_quote_characters
    ***********************************************************/
    public void set_return_delimiters (bool enable) {
        tokenizer_private.return_delimiters = enable;
    }


    /***********************************************************
    Sets characters that are considered to on_start and end quotes.

    When between two characters considered a quote, delimiters will
    be ignored.

    When between quotes, blackslash characters will cause the GLib.Tokenizer
    to skip the next character.

    \param quotes Characters that delimit quotes.
    ***********************************************************/
    public void set_quote_characters (T quotes) {
        tokenizer_private.quotes = quotes;
    }


    /***********************************************************
    Whether or not to return delimiters as tokens
    \see set_quote_characters
    ***********************************************************/
    public void set_return_quote_characters (bool enable) {
        tokenizer_private.return_quotes = enable;
    }


    /***********************************************************
    Retrieve next token.

    Returns true if there are more tokens, false otherwise.

    \sa next ()
    ***********************************************************/
    public bool has_next () {
        //  typename GLib.TokenizerPrivate<T, ConstIterator>.State state;
        tokenizer_private.is_delim = false;
        for (;;) {
            tokenizer_private.token_begin = tokenizer_private.token_end;
            if (tokenizer_private.token_end == tokenizer_private.end) {
                return false;
            }
            tokenizer_private.token_end++;
            if (tokenizer_private.next_char (&state, *tokenizer_private.token_begin)) {
                break;
            }
            if (tokenizer_private.return_delimiters) {
                tokenizer_private.is_delim = true;
                return true;
            }
        }
        while (tokenizer_private.token_end != tokenizer_private.end && tokenizer_private.next_char (&state, *tokenizer_private.token_end)) {
            tokenizer_private.token_end++;
        }
        return true;
    }


    /***********************************************************
    Resets the tokenizer to the starting position.
    ***********************************************************/
    public void on_reset () {
        tokenizer_private.token_end = tokenizer_private.begin;
    }


    /***********************************************************
    Returns true if the current token is a delimiter,
    if one more more delimiting characters have been set.
    ***********************************************************/
    public bool is_delimiter () {
        return tokenizer_private.is_delim;
    }


    /***********************************************************
    Returns the current token.

    Use \c has_next () to fetch the next token.
    ***********************************************************/
    public T next () {
        int len = std.distance (tokenizer_private.token_begin, tokenizer_private.token_end);
        ConstIterator temporary_start = tokenizer_private.token_begin;
        if (!tokenizer_private.return_quotes && len > 1 && tokenizer_private.is_quote (*tokenizer_private.token_begin)) {
            temporary_start++;
            len -= 2;
        }
        return new T (temporary_start, len);
    }

}
