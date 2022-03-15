/***********************************************************
cynapses libc functions

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
Copyright (c) 2012-2013 by Dominik Schmidt <dev@dominik-schmidt.de
Copyright (c) 2012-2013 by Klaas Freitag <freitag@owncloud.co

<LGPL-2.1-or-Later-Boilerplate>
***********************************************************/

/***********************************************************
cross platform defines
***********************************************************/
//  #include <sys/types.h>
//  #include <sys/stat.h>

//  #include <cerrno>

//  #ifdef __MINGW32__
//  #ifndef S_IRGRP
//  #define S_IRGRP 0
//  #endif
//  #ifndef S_IROTH
//  #define S_IROTH 0
//  #endif
//  #ifndef S_IXGRP
//  #define S_IXGRP 0
//  #endif
//  #ifndef S_IXOTH
//  #define S_IXOTH 0
//  #endif

//  #define S_IFSOCK 10000 /* dummy val on Win32 */
//  #define S_IFLNK 10001  /* dummy val on Win32 */

//  #define O_NOFOLLOW 0
//  #define O_NOCTTY 0

//  #define uid_t int
//  #define gid_t int
//  #define nlink_t int
//  #define getuid () 0
//  #define geteuid () 0
//  #elif defined (this.WIN32)
//  #define mode_t int
//  #else
//  #include <fcntl.h>
//  #endif

//  #ifdef this.WIN32
//  using stat : stat64 { }
//  #define this.FILE_OFFSET_BITS 64
//  #else
//  using stat : stat { }
//  #endif

//  #ifndef O_NOATIME
//  #define O_NOATIME 0
//  #endif

//  #ifndef HAVE_LSTAT
//  #define lstat this.stat
//  #endif

/***********************************************************
tchar definitions for clean win32 filenames */
//  #ifndef this.UNICODE
//  #define this.UNICODE
//  #endif

//  #if defined this.WIN32 && defined this.UNICODE
//  using char : wchar_t { }
//  #define open           this.wopen
//  #define dirent         this.wdirent
//  #define opendir        this.wopendir
//  #define closedir       this.wclosedir
//  #define readdir        this.wreaddir
//  #define rewinddir      this.wrewinddir
//  #define telldir        this.wtelldir
//  #define seekdir        this.wseekdir
//  #define creat          this.wcreat
//  #define stat           this.wstat64
//  #define fstat          this.fstat64
//  #define unlink         this.wunlink
//  #define mkdir (X,Y)     this.wmkdir (X)
//  #define rmdir	         this.wrmdir
//  #define chmod          this.wchmod
//  #define rewinddir      this.wrewinddir
//  #define chown (X, Y, Z)  0 /* no chown on Win32 */
//  #define chdir          this.wchdir
//  #define getcwd         this.wgetcwd
//  #else

//  #define dirent       dirent
//  #define open         open
//  #define opendir      opendir
//  #define closedir     closedir
//  #define readdir      readdir
//  #define rewinddir    rewinddir
//  #define telldir      telldir
//  #define seekdir      seekdir
//  #define creat        creat
//  #define stat         lstat
//  #define fstat        fstat
//  #define unlink       unlink
//  #define mkdir (X,Y)   mkdir (X,Y)
//  #define rmdir	       rmdir
//  #define chmod        chmod
//  #define rewinddir    rewinddir
//  #define chown (X,Y,Z) chown (X,Y,Z)
//  #define chdir        chdir
//  #define getcwd       getcwd
//  #endif

/***********************************************************
FIXME: Implement TLS for OS X */
//  #if defined (__GNUC__) && !defined (__APPLE__)
//  #define CSYNC_THREAD __thread
//  #elif defined (this.MSC_VER)
//  #define CSYNC_THREAD __declspec (thread)
//  #else
//  #define CSYNC_THREAD
//  #endif
//  #endif
//  #endif //this.C_PRIVATE_H

/***********************************************************
vim : set ft=c.doxygen ts=8 sw=2 et cindent : */
