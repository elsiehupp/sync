#ifndef WORDLIST_H
#define WORDLIST_H

// #include <QList>
// #include <QString>

namespace OCC {
    namespace WordList {
        OWNCLOUDSYNC_EXPORT QStringList getRandomWords(int nr);
        OWNCLOUDSYNC_EXPORT QString getUnifiedString(QStringList& l);
    }
}

#endif
