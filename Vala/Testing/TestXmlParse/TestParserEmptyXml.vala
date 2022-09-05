namespace Occ {
namespace Testing {

/***********************************************************
@class TestParserEmptyXml

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestParserEmptyXml : AbstractTestXmlParse {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestParserEmptyXml () {
    //      string xml_string = "";

    //      LscolXMLParser lscol_xml_parser;

    //      lscol_xml_parser.signal_directory_listing_subfolders.connect (
    //          this.on_signal_directory_listing_sub_folders
    //      );
    //      lscol_xml_parser.signal_directory_listing_iterated.connect (
    //          this.on_signal_directory_listing_iterated
    //      );
    //      lscol_xml_parser.signal_finished_without_error.connect (
    //          this.on_signal_finished_successfully
    //      );

    //      GLib.HashTable <string, ExtraFolderInfo> sizes;
    //      GLib.assert_true (false == lscol_xml_parser.parse ( xml_string, sizes, "/oc/remote.php/dav/sharefolder" )); // verify false

    //      GLib.assert_true (!this.success);
    //      GLib.assert_true (sizes.size () == 0 ); // No quota info in the XML

    //      GLib.assert_true (this.items.size () == 0 ); // FIXME: We should change the lscol_xml_parser to not emit during parsing but at the end
    //      GLib.assert_true (this.subdirectories.size () == 0);
    //  }

} // class TestParserEmptyXml

} // namespace Testing
} // namespace Occ
