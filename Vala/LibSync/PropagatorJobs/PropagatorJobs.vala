/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <qfile.h>
//  #include <qdir.h>
//  #include <qdiriterator.h>
//  #include <qtemporaryfile.h>
//  #include <qsavefile.h>
//  #include <qstack.h>
//  #include <QCoreApplication>
//  #include
//  #include <ctime>

//  #pragma once


namespace Occ {

/***********************************************************
Tags for checksum header.
It's here for being shared between Upload- and Download Job
***********************************************************/
static const char check_sum_header_c[] = "OC-Checksum";
static const char content_md5Header_c[] = "Content-MD5";




    GLib.ByteArray local_file_id_from_full_id (GLib.ByteArray identifier) {
        return identifier.left (8);
    }


    