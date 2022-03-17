/***********************************************************
   This software is in the public domain, furnished "as is", without technical
      support, and with no warranty, express or implied, as to its usefulness for
         any purpose.
         */

//  #include <QtTest>

using Occ;

namespace Testing {

public class TestXmlParse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private bool success;
    private string[] subdirectories;
    private string[] items;


    /***********************************************************
    ***********************************************************/
    public void on_signal_directory_listing_sub_folders (string[] list) {
        GLib.debug ("subfolders: " + list.join ("/n"));
        this.subdirectories.append (list);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_directory_listing_iterated (string item, GLib.HashTable<string,string> map) {
        GLib.debug ("     item: " + item);
        this.items.append (item);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_finished_successfully () {
        this.success = true;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init () {
        GLib.debug (Q_FUNC_INFO);
        this.success = false;
        delete (this.subdirectories);
        delete (this.items);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_cleanup () {}


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser1 () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (parser.parse (test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));

        GLib.assert_true (this.success);
        GLib.assert_true (sizes.size () == 1); // Quota info in the XML

        GLib.assert_true (this.items.contains ("/oc/remote.php/dav/sharefolder/quitte.pdf"));
        GLib.assert_true (this.items.contains ("/oc/remote.php/dav/sharefolder"));
        GLib.assert_true (this.items.size () == 2 );

        GLib.assert_true (this.subdirectories.contains ("/oc/remote.php/dav/sharefolder/"));
        GLib.assert_true (this.subdirectories.size () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_broken_xml () {
        const string test_xml = "X<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (false == parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        GLib.assert_true (!this.success);
        GLib.assert_true (sizes.size () == 0 ); // No quota info in the XML

        GLib.assert_true (this.items.size () == 0 ); // FIXME: We should change the parser to not emit during parsing but at the end

        GLib.assert_true (this.subdirectories.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_empty_xml_no_dav () {
        const string test_xml = "<html><body>I am under construction</body></html>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (false == parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        GLib.assert_true (!this.success);
        GLib.assert_true (sizes.size () == 0 ); // No quota info in the XML

        GLib.assert_true (this.items.size () == 0 ); // FIXME: We should change the parser to not emit during parsing but at the end
        GLib.assert_true (this.subdirectories.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_empty_xml () {
        const string test_xml = "";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (false == parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

        GLib.assert_true (!this.success);
        GLib.assert_true (sizes.size () == 0 ); // No quota info in the XML

        GLib.assert_true (this.items.size () == 0 ); // FIXME: We should change the parser to not emit during parsing but at the end
        GLib.assert_true (this.subdirectories.size () == 0);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_truncated_xml () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"; // no proper end here

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (!parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));
        GLib.assert_true (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_bogus_href1 () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>http://127.0.0.1:81/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>http://127.0.0.1:81/oc/remote.php/dav/sharefolder/quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (false == parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));
        GLib.assert_true (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_bogus_href2 () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/sharefolder</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/sharefolder/quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (false == parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));
        GLib.assert_true (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_denormalized_path () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/../sharefolder/quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));

        GLib.assert_true (this.success);
        GLib.assert_true (sizes.size () == 1); // Quota info in the XML

        GLib.assert_true (this.items.contains ("/oc/remote.php/dav/sharefolder/quitte.pdf"));
        GLib.assert_true (this.items.contains ("/oc/remote.php/dav/sharefolder"));
        GLib.assert_true (this.items.size () == 2 );

        GLib.assert_true (this.subdirectories.contains ("/oc/remote.php/dav/sharefolder/"));
        GLib.assert_true (this.subdirectories.size () == 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_parser_denormalized_path_outside_namespace () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/oc/remote.php/dav/sharefolder/../quitte.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (!parser.parse ( test_xml, sizes, "/oc/remote.php/dav/sharefolder" ));

        GLib.assert_true (!this.success);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_href_url_encoding () {
        const string test_xml = "<?xml version='1.0' encoding='utf-8'?>"
            + "<d:multistatus xmlns:d=\"DAV:\" xmlns:s=\"http://sabredav.org/ns\" xmlns:oc=\"http://owncloud.org/ns\">"
            + "<d:response>"
            + "<d:href>/%C3%A4</d:href>" // a-umlaut utf8
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004213ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVCK</oc:permissions>"
            + "<oc:size>121780</oc:size>"
            + "<d:getetag>\"5527beb0400b0\"</d:getetag>"
            + "<d:resourcetype>"
            + "<d:collection/>"
            + "</d:resourcetype>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<d:getcontentlength/>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "<d:response>"
            + "<d:href>/%C3%A4/%C3%A4.pdf</d:href>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:identifier>00004215ocobzus5kn6s</oc:identifier>"
            + "<oc:permissions>RDNVW</oc:permissions>"
            + "<d:getetag>\"2fa2f0d9ed49ea0c3e409d49e652dea0\"</d:getetag>"
            + "<d:resourcetype/>"
            + "<d:getlastmodified>Fri, 06 Feb 2015 13:49:55 GMT</d:getlastmodified>"
            + "<d:getcontentlength>121780</d:getcontentlength>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 200 OK</d:status>"
            + "</d:propstat>"
            + "<d:propstat>"
            + "<d:prop>"
            + "<oc:downloadURL/>"
            + "<oc:dDC/>"
            + "</d:prop>"
            + "<d:status>HTTP/1.1 404 Not Found</d:status>"
            + "</d:propstat>"
            + "</d:response>"
            + "</d:multistatus>";

        LsColXMLParser parser;

        connect (
            parser,
            signal_directory_listing_subfolders,
            this,
            on_signal_directory_listing_sub_folders
        );
        connect (
            parser,
            signal_directory_listing_iterated,
            this,
            on_signal_directory_listing_iterated
        );
        connect (
            parser,
            finished_without_error,
            this,
            on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (
            parser.parse (
                test_xml,
                sizes,
                "/ä"
            )
        );
        GLib.assert_true (this.success);

        GLib.assert_true (this.items.contains ("/ä/ä.pdf"));
        GLib.assert_true (this.items.contains ("/ä"));
        GLib.assert_true (this.items.size () == 2 );

        GLib.assert_true (this.subdirectories.contains ("/ä"));
        GLib.assert_true (this.subdirectories.size () == 1);
    }

} // class TestXmlParse 
} // namespace Testing
