
class QStringTokenizer : QTokenizer<string> {

    /***********************************************************
    ***********************************************************/
    public QStringTokenizer (string string, string delim) :
        QTokenizer<string, string.Const_iterator> (string, delim) {}
    /***********************************************************
    @brief Like \see next (), but returns a lightweight string reference
    @return A reference to the token within the string
    ***********************************************************/
    public QStringRef string_ref () {
        // If those differences overflow an int we'd have a veeeeeery long string in memory
        int begin = std.distance (d.begin, d.token_begin);
        int end = std.distance (d.token_begin, d.token_end);
        if (!d.return_quotes && d.is_quote (*d.token_begin)) {
            begin++;
            end -= 2;
        }
        return QStringRef (&d.string, begin, end);
    }
};