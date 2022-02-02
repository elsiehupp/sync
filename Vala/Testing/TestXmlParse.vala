/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

// #include <QtTest>

using namespace Occ;

class TestXmlParse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private bool this.success;
    private string[] this.subdirs;
    private string[] this.items;


    /***********************************************************
    ***********************************************************/
    public void on_directory_listing_sub_folders (string[]& list) {
        qDebug () << "subfolders : " << list;
        this.subdirs.append (list);
    }


    /***********************************************************
    ***********************************************************/
    public void on_directory_listing_iterated (string& item, QMap<string,string>& ) {
        qDebug () << "     item : " << item;
        this.items.append (item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_finished_successfully () {
        this.success = true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_init () {
        qDebug () << Q_FUNC_INFO;
        this.success = false;
        this.subdirs.clear ();
        this.items.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_cleanup () {}


    private
    private void on_test_parser1 () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));

        QVERIFY (this.success);
        QCOMPARE (sizes.size (), 1 ); // Quota info in the XML

        QVERIFY (this.items.contains ("/oc/remote.php/dav/sharefolder/quitte.pdf"));
        QVERIFY (this.items.contains ("/oc/remote.php/dav/sharefolder"));
        QVERIFY (this.items.size () == 2 );

        QVERIFY (this.subdirs.contains ("/oc/remote.php/dav/sharefolder/"));
        QVERIFY (this.subdirs.size () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_broken_xml () {
        const GLib.ByteArray testXml = "X<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (false == parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        QVERIFY (!this.success);
        QVERIFY (sizes.size () == 0 ); // No quota info in the XML

        QVERIFY (this.items.size () == 0 ); // FIXME : We should change the parser to not emit during parsing but at the end

        QVERIFY (this.subdirs.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_empty_xml_no_dav () {
        const GLib.ByteArray testXml = "<html><body>I am under construction</body></html>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (false == parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        QVERIFY (!this.success);
        QVERIFY (sizes.size () == 0 ); // No quota info in the XML

        QVERIFY (this.items.size () == 0 ); // FIXME : We should change the parser to not emit during parsing but at the end
        QVERIFY (this.subdirs.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_empty_xml () {
        const GLib.ByteArray testXml = "";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (false == parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        QVERIFY (!this.success);
        QVERIFY (sizes.size () == 0 ); // No quota info in the XML

        QVERIFY (this.items.size () == 0 ); // FIXME : We should change the parser to not emit during parsing but at the end
        QVERIFY (this.subdirs.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_truncated_xml () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"; // no proper end here

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (!parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));
        QVERIFY (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_bogus_href1 () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>http://127.0.0.1:81/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>http://127.0.0.1:81/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (false == parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));
        QVERIFY (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_bogus_href2 () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/sharefolder</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/sharefolder/quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (false == parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));
        QVERIFY (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_denormalized_path () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/../sharefolder/quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));

        QVERIFY (this.success);
        QCOMPARE (sizes.size (), 1 ); // Quota info in the XML

        QVERIFY (this.items.contains ("/oc/remote.php/dav/sharefolder/quitte.pdf"));
        QVERIFY (this.items.contains ("/oc/remote.php/dav/sharefolder"));
        QVERIFY (this.items.size () == 2 );

        QVERIFY (this.subdirs.contains ("/oc/remote.php/dav/sharefolder/"));
        QVERIFY (this.subdirs.size () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_parser_denormalized_path_outside_namespace () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/oc/remote.php/dav/sharefolder/../quitte.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (!parser.parse ( testXml, sizes, "/oc/remote.php/dav/sharefolder" ));

        QVERIFY (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_test_href_url_encoding () {
        const GLib.ByteArray testXml = "<?xml version='1.0' encoding='utf-8'?>"
            "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            "<d:response>"
            "<d:href>/%C3%A4</d:href>" // a-umlaut utf8
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004213ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVCK</oc:permissions>"
            "<oc:size>121780</oc:size>"
            "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            "<d:resourcetype>"
            "<d:collection/>"
            "</d:resourcetype>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<d:getcontentlength/>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "<d:response>"
            "<d:href>/%C3%A4/%C3%A4.pdf</d:href>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:id>00004215ocobzus5kn6s</oc:id>"
            "<oc:permissions>RDNVW</oc:permissions>"
            "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            "<d:resourcetype/>"
            "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            "<d:getcontentlength>121780</d:getcontentlength>"
            "</d:prop>"
            "<d:status>HTTP/1.1 200 OK</d:status>"
            "</d:propstat>"
            "<d:propstat>"
            "<d:prop>"
            "<oc:downloadURL/>"
            "<oc:dDC/>"
            "</d:prop>"
            "<d:status>HTTP/1.1 404 Not Found</d:status>"
            "</d:propstat>"
            "</d:response>"
            "</d:multistatus>";

        LsColXMLParser parser;

        connect ( parser, SIGNAL (directoryListingSubfolders (string[]&)),
                 this, SLOT (on_directory_listing_sub_folders (string[]&)) );
        connect ( parser, SIGNAL (directoryListingIterated (string&, QMap<string,string>&)),
                 this, SLOT (on_directory_listing_iterated (string&, QMap<string,string>&)) );
        connect ( parser, SIGNAL (finishedWithoutError ()),
                 this, SLOT (on_finished_successfully ()) );

        GLib.HashMap <string, ExtraFolderInfo> sizes;
        QVERIFY (parser.parse ( testXml, sizes, string.fromUtf8 ("/ä") ));
        QVERIFY (this.success);

        QVERIFY (this.items.contains (string.fromUtf8 ("/ä/ä.pdf")));
        QVERIFY (this.items.contains (string.fromUtf8 ("/ä")));
        QVERIFY (this.items.size () == 2 );

        QVERIFY (this.subdirs.contains (string.fromUtf8 ("/ä")));
        QVERIFY (this.subdirs.size () == 1);
    }

};

QTEST_GUILESS_MAIN (TestXmlParse)
