namespace Occ {
namespace Testing {

/***********************************************************
libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.

This library is free software; you can redistribute it and/o
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later vers

This library is distributed in the hope that it wi
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
***********************************************************/
public class TestCommandLine : GLib.Object {

    const string ARGP_PROGRAM_VERSION = "csync test 0.2";
    const string ARGP_PROGRAM_BUG_ADDRESS = "<csync-devel@csync.org>";

    static string command_line;

    /***********************************************************
    Program documentation.
    ***********************************************************/
    static string doc = "csync test";

    /***********************************************************
    The options we understand.
    ***********************************************************/
    //  static ArgpOption[] options = { ArgpOption (
    //          .name    = "verbose",
    //          .key     = 'v',
    //          .arg     = NULL,
    //          .flags = 0,
    //          .doc     = "Make csync test more verbose",
    //          .group = 0
    //      ), {NULL, 0, NULL, 0, NULL, 0}
    //  }

    /***********************************************************
    Parse a single option.
    ***********************************************************/
    static Error parse_opt (int key, char arg, ArgpState state) {
        /* Get the input argument from argp_parse, which we
        * know is a pointer to our arguments structure.
        */
        Arguments arguments = state.input;

        /* arg is currently not used */
        (void) arg;

        switch (key) {
            case 'v':
                arguments.verbose++;
                break;
            case ARGP_KEY_ARG:
                /* End processing here. */
                command_line = state.argv [state.next - 1];
                state.next = state.argc;
                break;
            default:
                return ARGP_ERR_UNKNOWN;
        }

        return 0;
    }


    /***********************************************************
    Our argp parser. */
    /***********************************************************
    static struct argp argp = {options, parse_opt, args_doc, doc, NULL, NULL, NULL}; */
    static argp ArgP = {options, parse_opt, NULL, doc, NULL, NULL, NULL};
    //    #endif /* HAVE_ARGP_H */

    void torture_cmdline_parse (int argc, char **argv, Arguments arguments) {
        /***********************************************************
        * Parse our arguments; every option seen by parse_opt will
        * be reflected in arguments.
        */
    //  #ifdef HAVE_ARGP_H
        argp_parse (&argp, argc, argv, 0, 0, arguments);
    //  #else
        (void) argc;
        (void) argv;
        (void) arguments;
    //    #endif /* HAVE_ARGP_H */
    }
}
