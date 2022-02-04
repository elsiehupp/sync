/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/


namespace SharedTools {

class QtLockedFile : GLib.File {

    /***********************************************************
    ***********************************************************/
    public enum LockMode {
        NO_LOCK = 0,
        READ_LOCK,
        WRITE_LOCK
    };

    /***********************************************************
    ***********************************************************/
    public QtLockedFile ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public edFile () override;

    /***********************************************************
    ***********************************************************/
    public bool lock (LockM

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public bool is_locked ();


    public LockMode lock_mode ();


    /***********************************************************
    ***********************************************************/
    private LockMode m_lock_mode;
}

} // namespace SharedTools











/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

namespace SharedTools {

    /***********************************************************
    \class QtLockedFile

    \brief The QtLockedFile class extends GLib.File with advisory locking functions.

    A file may be locked in read or write mode. Multiple instances of
    \e QtLockedFile, created in multiple processes running on the same
    machine, may have a file locked in read mode. Exactly one instance
    may have it locked in write mode. A read and a write lock cannot
    exist simultaneously on the same file.

    The file locks are advisory. This means that nothing prevents
    another process from manipulating a locked file using GLib.File or
    file system functions offered by the OS. Serialization is only
    guaranteed if all processes that access the file use
    QtLockedFile. Also, while holding a lock on a file, a process
    must not open the same file again (through any API), or locks
    can be unexpectedly lost.

    The lock provided by an instance of \e QtLockedFile is released
    whenever the program terminates. This is true even when the
    program crashes and no destructors are called.
    ***********************************************************/

    /*********************************************************** \enum QtLockedFile.LockMode

    This enum describes the available lock modes.

    \value LockMode.READ_LOCK A read lock.
    \value LockMode.WRITE_LOCK A write lock.
    \value LockMode.NO_LOCK Neither a read lock nor a write lock.
    ***********************************************************/

    /***********************************************************
        Constructs an unlocked \e QtLockedFile object. This constructor behaves in the same way
    as \e GLib.File.GLib.File ().

    \sa GLib.File.GLib.File ()
    ***********************************************************/
    QtLockedFile.QtLockedFile ()
        : GLib.File () {
        m_lock_mode = LockMode.NO_LOCK;
    }


    /***********************************************************
    Constructs an unlocked QtLockedFile object with file \a name. This constructor behaves in
    the same way as \e GLib.File.GLib.File (string&).

    \sa GLib.File.GLib.File ()
    ***********************************************************/
    QtLockedFile.QtLockedFile (string name)
        : GLib.File (name) {
        m_lock_mode = LockMode.NO_LOCK;
    }


    /***********************************************************
    Returns \e true if this object has a in read or write lock;
    otherwise returns \e false.

    \sa lock_mode ()
    ***********************************************************/
    bool QtLockedFile.is_locked () {
        return m_lock_mode != LockMode.NO_LOCK;
    }


    /***********************************************************
    Returns the type of lock currently held by this object, or \e QtLockedFile.LockMode.NO_LOCK.

    \sa is_locked ()
    ***********************************************************/
    QtLockedFile.LockMode QtLockedFile.lock_mode () {
        return m_lock_mode;
    }


    /***********************************************************
    \fn bool QtLockedFile.lock (LockMode mode, bool block = true)

    Obtains a lock of type \a mode.

    If \a block is true, this
    function will block until the lock is acquired. If \a block is
    false, this function returns \e false immediately if the lock cannot
    be acquired.

    If this object already has a lock of type \a mode, this function returns \e true immediately. If this object has a lock of a different type than \a mode, the lock
    is first released and then a new lock is obtained.

    This function returns \e true if, after it executes, the file is locked by this object,
    and \e false otherwise.

    \sa unlock (), is_locked (), lock_mode ()
    ***********************************************************/

    /***********************************************************
    \fn bool QtLockedFile.unlock ()

    Releases a lock.

    If the object has no lock, this function returns immediately.

    This function returns \e true if, after it executes, the file is not locked by
    this object, and \e false otherwise.

    \sa lock (), is_locked (), lock_mode ()
    ***********************************************************/

    /***********************************************************
    \fn QtLockedFile.~QtLockedFile ()

    Destroys the \e QtLockedFile object. If any locks were held, they are released.
    ***********************************************************/

    } // namespace SharedTools














/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

//  #include <cstring>
//  #include <cerrno>
//  #include <unistd.h>
//  #include <fcntl.h>

namespace SharedTools {

    bool QtLockedFile.lock (LockMode mode, bool block) {
        if (!is_open ()) {
            q_warning ("QtLockedFile.lock () : file is not opened");
            return false;
        }

        if (mode == LockMode.NO_LOCK)
            return unlock ();

        if (mode == m_lock_mode)
            return true;

        if (m_lock_mode != LockMode.NO_LOCK)
            unlock ();

        struct flock fl;
        fl.l_whence = SEEK_SET;
        fl.l_start = 0;
        fl.l_len = 0;
        fl.l_type = (mode == LockMode.READ_LOCK) ? F_RDLCK : F_WRLCK;
        int cmd = block ? F_SETLKW : F_SETLK;
        int ret = fcntl (handle (), cmd, fl);

        if (ret == -1) {
            if (errno != EINTR && errno != EAGAIN)
                q_warning ("QtLockedFile.lock () : fcntl : %s", strerror (errno));
            return false;
        }

        m_lock_mode = mode;
        return true;
    }

    bool QtLockedFile.unlock () {
        if (!is_open ()) {
            q_warning ("QtLockedFile.unlock () : file is not opened");
            return false;
        }

        if (!is_locked ())
            return true;

        struct flock fl;
        fl.l_whence = SEEK_SET;
        fl.l_start = 0;
        fl.l_len = 0;
        fl.l_type = F_UNLCK;
        int ret = fcntl (handle (), F_SETLKW, fl);

        if (ret == -1) {
            q_warning ("QtLockedFile.lock () : fcntl : %s", strerror (errno));
            return false;
        }

        m_lock_mode = LockMode.NO_LOCK;
        remove ();
        return true;
    }

    QtLockedFile.~QtLockedFile () {
        if (is_open ())
            unlock ();
    }

    } // namespace SharedTools
    