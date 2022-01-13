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

/* cross platform defines */
// #include <sys/types.h>
// #include <sys/stat.h>

#ifdef _WIN32
// #include <windows.h>
// #include <windef.h>
// #include <winbase.h>
// #include <wchar.h>
#else
// #include <unistd.h>
#endif

// #include <cerrno>

#ifdef __MINGW32__
#ifndef S_IRGRP
const int S_IRGRP 0
#endif
#ifndef S_IROTH
const int S_IROTH 0
#endif
#ifndef S_IXGRP
const int S_IXGRP 0
#endif
#ifndef S_IXOTH
const int S_IXOTH 0
#endif

const int S_IFSOCK 10000 /* dummy val on Win32 */
const int S_IFLNK 10001  /* dummy val on Win32 */

const int O_NOFOLLOW 0
const int O_NOCTTY 0

const int uid_t int
const int gid_t int
const int nlink_t int
const int getuid () 0
const int geteuid () 0
#elif defined (_WIN32)
const int mode_t int
#else
// #include <fcntl.h>
#endif

#ifdef _WIN32
using csync_stat_t = struct stat64;
const int _FILE_OFFSET_BITS 64
#else
using csync_stat_t = struct stat;
#endif

#ifndef O_NOATIME
const int O_NOATIME 0
#endif

#ifndef HAVE_LSTAT
const int lstat _stat
#endif

/* tchar definitions for clean win32 filenames */
#ifndef _UNICODE
const int _UNICODE
#endif

#if defined _WIN32 && defined _UNICODE
using mbchar_t = wchar_t;
const int _topen           _wopen
const int _tdirent         _wdirent
const int _topendir        _wopendir
const int _tclosedir       _wclosedir
const int _treaddir        _wreaddir
const int _trewinddir      _wrewinddir
const int _ttelldir        _wtelldir
const int _tseekdir        _wseekdir
const int _tcreat          _wcreat
const int _tstat           _wstat64
const int _tfstat          _fstat64
const int _tunlink         _wunlink
const int _tmkdir (X,Y)     _wmkdir (X)
const int _trmdir	         _wrmdir
const int _tchmod          _wchmod
const int _trewinddir      _wrewinddir
const int _tchown (X, Y, Z)  0 /* no chown on Win32 */
const int _tchdir          _wchdir
const int _tgetcwd         _wgetcwd
#else
using mbchar_t = char;
const int _tdirent       dirent
const int _topen         open
const int _topendir      opendir
const int _tclosedir     closedir
const int _treaddir      readdir
const int _trewinddir    rewinddir
const int _ttelldir      telldir
const int _tseekdir      seekdir
const int _tcreat        creat
const int _tstat         lstat
const int _tfstat        fstat
const int _tunlink       unlink
const int _tmkdir (X,Y)   mkdir (X,Y)
const int _trmdir	       rmdir
const int _tchmod        chmod
const int _trewinddir    rewinddir
const int _tchown (X,Y,Z) chown (X,Y,Z)
const int _tchdir        chdir
const int _tgetcwd       getcwd
#endif

/* FIXME : Implement TLS for OS X */
#if defined (__GNUC__) && !defined (__APPLE__)
# define CSYNC_THREAD __thread
#elif defined (_MSC_VER)
# define CSYNC_THREAD __declspec (thread)
#else
# define CSYNC_THREAD
#endif

#endif //_C_PRIVATE_H

/* vim : set ft=c.doxygen ts=8 sw=2 et cindent : */
