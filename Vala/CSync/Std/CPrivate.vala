/***********************************************************
cynapses libc functions

Copyright (c) 2008-2013 by Andreas Schneider <asn@cryptomilk.org>
Copyright (c) 2012-2013 by Dominik Schmidt <dev@dominik-schmidt.de
Copyright (c) 2012-2013 by Klaas Freitag <freitag@owncloud.co

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/

/***********************************************************
cross platform defines */
//  #include <sys/types.h>
//  #include <sys/stat.h>

#ifdef this.WIN32
//  #include <windows.h>
//  #include <windef.h>
//  #include <winbase.h>
//  #include <wchar.h>
//  #include <unistd.h>
//  #endif

//  #include <cerrno>

#ifdef __MINGW32__
//  #ifndef S_IRGRP
const int S_IRGRP 0
//  #endif
//  #ifndef S_IROTH
const int S_IROTH 0
//  #endif
//  #ifndef S_IXGRP
const int S_IXGRP 0
//  #endif
//  #ifndef S_IXOTH
const int S_IXOTH 0
//  #endif

const int S_IFSOCK 10000 /* dummy val on Win32 */
const int S_IFLNK 10001  /* dummy val on Win32 */

const int O_NOFOLLOW 0
const int O_NOCTTY 0

const int uid_t int
const int gid_t int
const int nlink_t int
const int getuid () 0
const int geteuid () 0
#elif defined (this.WIN32)
const int mode_t int
#else
//  #include <fcntl.h>
//  #endif

#ifdef this.WIN32
using csync_stat_t = struct stat64;
const int this.FILE_OFFSET_BITS 64
#else
using csync_stat_t = struct stat;
//  #endif

//  #ifndef O_NOATIME
const int O_NOATIME 0
//  #endif

//  #ifndef HAVE_LSTAT
const int lstat this.stat
//  #endif

/***********************************************************
tchar definitions for clean win32 filenames */
//  #ifndef this.UNICODE
const int this.UNICODE
//  #endif

#if defined this.WIN32 && defined this.UNICODE
using mbchar_t = wchar_t;
const int this.topen           this.wopen
const int this.tdirent         this.wdirent
const int this.topendir        this.wopendir
const int this.tclosedir       this.wclosedir
const int this.treaddir        this.wreaddir
const int this.trewinddir      this.wrewinddir
const int this.ttelldir        this.wtelldir
const int this.tseekdir        this.wseekdir
const int this.tcreat          this.wcreat
const int this.tstat           this.wstat64
const int this.tfstat          this.fstat64
const int this.tunlink         this.wunlink
const int this.tmkdir (X,Y)     this.wmkdir (X)
const int this.trmdir	         this.wrmdir
const int this.tchmod          this.wchmod
const int this.trewinddir      this.wrewinddir
const int this.tchown (X, Y, Z)  0 /* no chown on Win32 */
const int this.tchdir          this.wchdir
const int this.tgetcwd         this.wgetcwd
#else
using mbchar_t = char;
const int this.tdirent       dirent
const int this.topen         open
const int this.topendir      opendir
const int this.tclosedir     closedir
const int this.treaddir      readdir
const int this.trewinddir    rewinddir
const int this.ttelldir      telldir
const int this.tseekdir      seekdir
const int this.tcreat        creat
const int this.tstat         lstat
const int this.tfstat        fstat
const int this.tunlink       unlink
const int this.tmkdir (X,Y)   mkdir (X,Y)
const int this.trmdir	       rmdir
const int this.tchmod        chmod
const int this.trewinddir    rewinddir
const int this.tchown (X,Y,Z) chown (X,Y,Z)
const int this.tchdir        chdir
const int this.tgetcwd       getcwd
//  #endif

/***********************************************************
FIXME : Implement TLS for OS X */
#if defined (__GNUC__) && !defined (__APPLE__)
# define CSYNC_THREAD __thread
#elif defined (this.MSC_VER)
# define CSYNC_THREAD __declspec (thread)
#else
# define CSYNC_THREAD
//  #endif
//  #endif
#endif //this.C_PRIVATE_H

/***********************************************************
vim : set ft=c.doxygen ts=8 sw=2 et cindent : */
