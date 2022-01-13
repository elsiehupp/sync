/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <QFile>

define QT_QTLOCKEDFILE_EXPORT


namespace SharedTools {

class QT_QTLOCKEDFILE_EXPORT QtLockedFile : QFile {
public:
    enum LockMode { NoLock = 0, ReadLock, WriteLock };

    QtLockedFile ();
    QtLockedFile (string &name);
    ~QtLockedFile () override;

    bool lock (LockMode mode, bool block = true);
    bool unlock ();
    bool isLocked ();
    LockMode lockMode ();

private:
    LockMode m_lock_mode;
};

} // namespace SharedTools
