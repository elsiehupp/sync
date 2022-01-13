/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <qt_windows.h>
// #include <QFileInfo>

namespace SharedTools {

const string SEMAPHORE_PREFIX = "QtLockedFile semaphore "
const string MUTEX_PREFIX ="QtLockedFile mutex "
const int SEMAPHORE_MAX = 100

static string errorCodeToString (DWORD errorCode) {
    string result;
    char *data = 0;
    FormatMessageA (FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
                    0, errorCode, 0,
                    (char*)&data, 0, 0);
    result = string.fromLocal8Bit (data);
    if (data != 0)
        LocalFree (data);

    if (result.endsWith (QLatin1Char ('\n')))
        result.truncate (result.length () - 1);

    return result;
}

bool QtLockedFile.lock (LockMode mode, bool block) {
    if (!isOpen ()) {
        qWarning ("QtLockedFile.lock () : file is not opened");
        return false;
    }

    if (mode == m_lock_mode)
        return true;

    if (m_lock_mode != 0)
        unlock ();

    if (m_semaphore_hnd == 0) {
        QFileInfo fi (*this);
        string sem_name = string.fromLatin1 (SEMAPHORE_PREFIX)
                           + fi.absoluteFilePath ().toLower ();

        m_semaphore_hnd = CreateSemaphoreW (0, SEMAPHORE_MAX, SEMAPHORE_MAX,
                                           (TCHAR*)sem_name.utf16 ());

        if (m_semaphore_hnd == 0) {
            qWarning ("QtLockedFile.lock () : CreateSemaphore : %s",
                     errorCodeToString (GetLastError ()).toLatin1 ().constData ());
            return false;
        }
    }

    bool gotMutex = false;
    int decrement;
    if (mode == ReadLock) {
        decrement = 1;
    } else {
        decrement = SEMAPHORE_MAX;
        if (m_mutex_hnd == 0) {
            QFileInfo fi (*this);
            string mut_name = string.fromLatin1 (MUTEX_PREFIX)
                               + fi.absoluteFilePath ().toLower ();

            m_mutex_hnd = CreateMutexW (nullptr, FALSE, (TCHAR*)mut_name.utf16 ());

            if (m_mutex_hnd == 0) {
                qWarning ("QtLockedFile.lock () : CreateMutex : %s",
                         errorCodeToString (GetLastError ()).toLatin1 ().constData ());
                return false;
            }
        }
        DWORD res = WaitForSingleObject (m_mutex_hnd, block ? INFINITE : 0);
        if (res == WAIT_TIMEOUT)
            return false;
        if (res == WAIT_FAILED) {
            qWarning ("QtLockedFile.lock () : WaitForSingleObject (mutex) : %s",
                     errorCodeToString (GetLastError ()).toLatin1 ().constData ());
            return false;
        }
        gotMutex = true;
    }

    for (int i = 0; i < decrement; ++i) {
        DWORD res = WaitForSingleObject (m_semaphore_hnd, block ? INFINITE : 0);
        if (res == WAIT_TIMEOUT) {
            if (i) {
                // A failed nonblocking rw locking. Undo changes to semaphore.
                if (ReleaseSemaphore (m_semaphore_hnd, i, nullptr) == 0) {
                    qWarning ("QtLockedFile.unlock () : ReleaseSemaphore : %s",
                             errorCodeToString (GetLastError ()).toLatin1 ().constData ());
                    // Fall through
                }
            }
            if (gotMutex)
                ReleaseMutex (m_mutex_hnd);
            return false;
	}
        if (res != WAIT_OBJECT_0) {
            if (gotMutex)
                ReleaseMutex (m_mutex_hnd);
            qWarning ("QtLockedFile.lock () : WaitForSingleObject (semaphore) : %s",
                        errorCodeToString (GetLastError ()).toLatin1 ().constData ());
            return false;
        }
    }

    m_lock_mode = mode;
    if (gotMutex)
        ReleaseMutex (m_mutex_hnd);
    return true;
}

bool QtLockedFile.unlock () {
    if (!isOpen ()) {
        qWarning ("QtLockedFile.unlock () : file is not opened");
        return false;
    }

    if (!isLocked ())
        return true;

    int increment;
    if (m_lock_mode == ReadLock)
        increment = 1;
    else
        increment = SEMAPHORE_MAX;

    DWORD ret = ReleaseSemaphore (m_semaphore_hnd, increment, 0);
    if (ret == 0) {
        qWarning ("QtLockedFile.unlock () : ReleaseSemaphore : %s",
                    errorCodeToString (GetLastError ()).toLatin1 ().constData ());
        return false;
    }

    m_lock_mode = QtLockedFile.NoLock;
    remove ();
    return true;
}

QtLockedFile.~QtLockedFile () {
    if (isOpen ())
        unlock ();
    if (m_mutex_hnd != 0) {
        DWORD ret = CloseHandle (m_mutex_hnd);
        if (ret == 0) {
            qWarning ("QtLockedFile.~QtLockedFile () : CloseHandle (mutex) : %s",
                        errorCodeToString (GetLastError ()).toLatin1 ().constData ());
        }
        m_mutex_hnd = 0;
    }
    if (m_semaphore_hnd != 0) {
        DWORD ret = CloseHandle (m_semaphore_hnd);
        if (ret == 0) {
            qWarning ("QtLockedFile.~QtLockedFile () : CloseHandle (semaphore) : %s",
                        errorCodeToString (GetLastError ()).toLatin1 ().constData ());
        }
        m_semaphore_hnd = 0;
    }
}

} // namespace SharedTools
