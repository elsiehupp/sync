namespace Occ {
namespace Testing {

/***********************************************************
@class TestParserTruncatedXml

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestParserTruncatedXml : AbstractTestXmlParse {

    /***********************************************************
    ***********************************************************/
    private TestParserTruncatedXml () {
        const string xml_string = "<?xml version='1.0' encoding='utf-8'?>"
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

        LscolXMLParser lscol_xml_parser;

        lscol_xml_parser.signal_directory_listing_subfolders.connect (
            this.on_signal_directory_listing_sub_folders
        );
        lscol_xml_parser.signal_directory_listing_iterated.connect (
            this.on_signal_directory_listing_iterated
        );
        lscol_xml_parser.signal_finished_without_error.connect (
            this.on_signal_finished_successfully
        );

        GLib.HashTable <string, ExtraFolderInfo> sizes;
        GLib.assert_true (!lscol_xml_parser.parse ( xml_string, sizes, "/oc/remote.php/dav/sharefolder" ));
        GLib.assert_true (!this.success);
    }

} // class TestParserTruncatedXml

} // namespace Testing
} // namespace Occ
