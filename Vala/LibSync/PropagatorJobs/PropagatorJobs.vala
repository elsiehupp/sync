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
//  #include <ctime>

namespace Occ {
namespace LibSync {

public class PropagatorJobs : GLib.Object {

    /***********************************************************
    Tags for checksum header.
    It's here for being shared between Upload- and Download Job
    ***********************************************************/
    const string CHECK_SUM_HEADER_C = "OC-Checksum";
    const string CONTENT_MD5_HEADER_C = "Content-MD5";

    public static string local_file_id_from_full_id (string identifier) {
        return identifier.left (8);
    }

} // class PropagatorJobs

} // namespace LibSync
} //namespace Occ
    