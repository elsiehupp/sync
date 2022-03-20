/***********************************************************
libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.

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
libcsync -- a library to sync a directory with another

@author 2008-2013 by Andreas Schneider <asn@cryptomilk.

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

//  #include <stdarg.h> // NOLINT sometimes compiled in C mode
//  #include <stddef.h> // NOLINT sometimes compiled in C mode
//  #include <setjmp.h> // NOLINT sometimes compiled in C mode
//  #include <cmocka.h>

namespace Occ {
namespace Testing {

public class Torture : GLib.Object {

    /***********************************************************
    Used by main to communicate with parse_opt.
    ***********************************************************/
    struct Arguments {
        char args[2];
        int verbose;
    }

    static int verbosity;

    void torture_cmdline_parse (int argc, char **argv, Arguments arguments);

    int torture_csync_verbosity () {
        return verbosity;
    }


    /***********************************************************
    This function must be defined in every unit test file.
    ***********************************************************/
    int torture_run_tests ();

    int main (int argc, char **argv) {
        Arguments arguments;

        arguments.verbose = 0;
        torture_cmdline_parse (argc, argv, arguments);
        verbosity = arguments.verbose;

        return torture_run_tests ();
    }

} // class Torture
} // namespace Testing
} // namespace Occ
