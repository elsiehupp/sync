/***********************************************************
Tests are taken form lookup2.c and lookup8.c
by Bob Jenkins, December 1996, Public Domain.

See http://burtleburtle.net/bob/hash/evahash.html
***********************************************************/

namespace Occ {
namespace Testing {

class CheckStdCJhash : GLib.Object {

    const int HASHSTATE = 1;
    const int HASHLEN   = 1;
    const int MAXPAIR   = 80;
    const int MAXLEN    = 70;

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash_trials (void **state) {
        uint8 qa[MAXLEN+1];
        uint8 qb[MAXLEN+2];
        uint8 *a = &qa[0];
        uint8 *b = &qb[1];
        uint32 c[HASHSTATE];
        uint32 d[HASHSTATE];
        uint32 i = 0;
        uint32 j = 0;
        uint32 k = 0;
        uint32 l = 0;
        uint32 m = 0;
        uint32 z = 0;
        uint32 e[HASHSTATE],f[HASHSTATE],g[HASHSTATE],h[HASHSTATE];
        uint32 x[HASHSTATE],y[HASHSTATE];
        uint32 hlen = 0;

        //  (void) state; /* unused */

        for (hlen=0; hlen < MAXLEN; ++hlen) {
            z=0;
            for (i=0; i<hlen; ++i) {    /*----------------------- for each input byte, */
                for (j=0; j<8; ++j) { /*------------------------ for each input bit, */
                    for (m=1; m<8; ++m) { /*------------ for serveral possible initvals, */
                        for (l=0; l<HASHSTATE; ++l) e[l]=f[l]=g[l]=h[l]=x[l]=y[l]=~ ( (uint32)0);

                        /*---- check that every output bit is affected by that input bit */
                        for (k=0; k<MAXPAIR; k+=2) {
                            uint32 finished=1;
                            /* keys have one bit different */
                            for (l=0; l<hlen+1; ++l) {a[l] = b[l] = (uint8)0;}
                            /* have a and b be two keys differing in only one bit */
                            a[i] ^= (k<<j);
                            a[i] ^= (k>> (8-j));
                            c[0] = c_jhash (a, hlen, m);
                            b[i] ^= ( (k+1)<<j);
                            b[i] ^= ( (k+1)>> (8-j));
                            d[0] = c_jhash (b, hlen, m);
                            /* check every bit is 1, 0, set, and not set at least once */
                            for (l=0; l<HASHSTATE; ++l) {
                                e[l] &= (c[l]^d[l]);
                                f[l] &= ~ (c[l]^d[l]);
                                g[l] &= c[l];
                                h[l] &= ~c[l];
                                x[l] &= d[l];
                                y[l] &= ~d[l];
                                if ((e[l]|f[l]|g[l]|h[l]|x[l]|y[l]) != 0) {
                                    finished = 0;
                                }
                            }
                            if (finished > 0) {
                                break;
                            }
                        }
                        if (k>z) z=k;
                        if (k==MAXPAIR) {
                            print_error ("Some bit didn't change: ");
                            print_error ("%.8x %.8x %.8x %.8x %.8x %.8x    ",
                                            e[0], f[0], g[0], h[0], x[0], y[0]);
                            print_error ("i %d j %d m %d len %d\n",i,j,m,hlen);
                        }
                        if (z == MAXPAIR) {
                                if (z < MAXPAIR) {
                                        GLib.assert_true (z < MAXPAIR);
                                        // print_error ("%u trials needed, should be less than 40\n", z/2);
                                        return;
                                }
                        }
                    }
                }
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash_alignment_problems (void **state) {
        uint32 test = 0;
        uint8 buf[MAXLEN+20];
        uint8 b = NULL;
        uint32 len = 0;
        uint8 q = "This is the time for all good men to come to the aid of their country";
        uint8 qq = "xThis is the time for all good men to come to the aid of their country";
        uint8 qqq = "xxThis is the time for all good men to come to the aid of their country";
        uint8 qqqq = "xxxThis is the time for all good men to come to the aid of their country";
        uint32 h = 0;
        uint32 i = 0;
        uint32 j = 0;
        uint32 ref = 0;
        uint32 x = 0;
        uint32 y = 0;

        (void) state; /* unused */

        test = c_jhash (q, sizeof (q)-1, (uint32)0);
        GLib.assert_true (test == c_jhash (qq+1, sizeof (q)-1, (uint32)0));
        GLib.assert_true (test == c_jhash (qq+1, sizeof (q)-1, (uint32)0));
        GLib.assert_true (test == c_jhash (qqq+2, sizeof (q)-1, (uint32)0));
        GLib.assert_true (test == c_jhash (qqqq+3, sizeof (q)-1, (uint32)0));
        for (h=0, b=buf+1; h<8; ++h, ++b) {
            for (i=0; i<MAXLEN; ++i) {
                len = i;
                for (j=0; j<i; ++j) * (b+j)=0;

                /* these should all be equal */
                ref = c_jhash (b, len, (uint32)1);
                * (b+i)= (uint8)~0;
                * (b-1)= (uint8)~0;
                x = c_jhash (b, len, (uint32)1);
                y = c_jhash (b, len, (uint32)1);
                assert_false ( (ref != x) || (ref != y));
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash_null_strings (void **state) {
        uint8 buf[1];
        uint32 h = 0;
        uint32 i = 0;
        uint32 t = 0;

        (void) state; /* unused */

        buf[0] = ~0;
        for (i=0, h=0; i<8; ++i) {
            t = h;
            h = c_jhash (buf, (uint32)0, h);
            assert_false (t == h);
            // print_error ("0-byte-string check failed : t = %.8x, h = %.8x", t, h);
        }
    }

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash64_trials (void **state) {
        uint8 qa[MAXLEN + 1];
        uint8 qb[MAXLEN + 2];
        uint8 *a = NULL;
        uint8 *b = NULL;
        uint64 c[HASHSTATE];
        uint64 d[HASHSTATE];
        uint64 i = 0;
        uint64 j=0;
        uint64 k = 0;
        uint64 l = 0;
        uint64 m = 0;
        uint64 z = 0;
        uint64 e[HASHSTATE];
        uint64 f[HASHSTATE];
        uint64 g[HASHSTATE];
        uint64 h[HASHSTATE];
        uint64 x[HASHSTATE];
        uint64 y[HASHSTATE];
        uint64 hlen = 0;

        (void) state; /* unused */

        a = qa[0];
        b = qb[1];

        for (hlen=0; hlen < MAXLEN; ++hlen) {
            z=0;
            for (i=0; i<hlen; ++i) { /*----------------------- for each byte, */
                for (j=0; j<8; ++j) { /*------------------------ for each bit, */
                    for (m=0; m<8; ++m) { /*-------- for serveral possible levels, */
                        for (l=0; l<HASHSTATE; ++l) e[l]=f[l]=g[l]=h[l]=x[l]=y[l]=~ ( (uint64)0);

                        /*---- check that every input bit affects every output bit */
                        for (k=0; k<MAXPAIR; k+=2) {
                            uint64 finished=1;
                            /* keys have one bit different */
                            for (l=0; l<hlen+1; ++l) {a[l] = b[l] = (uint8)0;}
                            /* have a and b be two keys differing in only one bit */
                            a[i] ^= (k<<j);
                            a[i] ^= (k>> (8-j));
                            c[0] = c_jhash64 (a, hlen, m);
                            b[i] ^= ( (k+1)<<j);
                            b[i] ^= ( (k+1)>> (8-j));
                            d[0] = c_jhash64 (b, hlen, m);
                            /* check every bit is 1, 0, set, and not set at least once */
                            for (l=0; l<HASHSTATE; ++l) {
                                e[l] &= (c[l]^d[l]);
                                f[l] &= ~ (c[l]^d[l]);
                                g[l] &= c[l];
                                h[l] &= ~c[l];
                                x[l] &= d[l];
                                y[l] &= ~d[l];
                                if ((e[l]|f[l]|g[l]|h[l]|x[l]|y[l]) != 0) {
                                    finished = 0;
                                }
                            }
                            if (finished > 0) {
                                break;
                            }
                        }
                        if (k>z) {
                            z=k;
                        }
                        if (k == MAXPAIR) {
    //  #if 0
                            print_error ("Some bit didn't change: ");
                            print_error ("%.8llx %.8llx %.8llx %.8llx %.8llx %.8llx    ",
                                (uint64) e[0],
                                (uint64) f[0],
                                (uint64) g[0],
                                (uint64) h[0],
                                (uint64) x[0],
                                (uint64) y[0]
                            );
                            print_error ("i %d j %d m %d len %d\n",
                                (uint32)i,
                                (uint32)j,
                                (uint32)m,
                                (uint32)hlen
                            );
    //  #endif
                        }
                        if (z == MAXPAIR) {
                                if (z < MAXPAIR) {
    #if 0
                                        print_error ("%lu trials needed, should be less than 40", z/2);
    //  #endif
                                        GLib.assert_true (z < MAXPAIR);
                                }
                                return;
                        }
                    }
                }
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash64_alignment_problems (void **state) {
        uint8 buf[MAXLEN+20];
        uint8 b = NULL;
        uint64 len = 0;
        uint8 q = "This is the time for all good men to come to the aid of their country";
        uint8 qq = "xThis is the time for all good men to come to the aid of their country";
        uint8 qqq = "xxThis is the time for all good men to come to the aid of their country";
        uint8 qqqq = "xxxThis is the time for all good men to come to the aid of their country";
        uint8 o = "xxxxThis is the time for all good men to come to the aid of their country";
        uint8 oo = "xxxxxThis is the time for all good men to come to the aid of their country";
        uint8 ooo = "xxxxxxThis is the time for all good men to come to the aid of their country";
        uint8 oooo = "xxxxxxxThis is the time for all good men to come to the aid of their country";
        uint64 h = 0;
        uint64 i = 0;
        uint64 j = 0;
        uint64 ref = 0;
        uint64 t = 0;
        uint64 x = 0;
        uint64 y = 0;

        (void) state; /* unused */

        h = c_jhash64 (q+0, (uint64) (sizeof (q)-1), (uint64)0);
        t = h;
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (qq+1, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (qqq+2, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (qqqq+3, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (o+4, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (oo+5, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (ooo+6, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        h = c_jhash64 (oooo+7, (uint64) (sizeof (q)-1), (uint64)0);
        GLib.assert_true (t == h);
        // , "%.8lx%.8lx\n", (uint32)h, (uint32) (h>>32));
        for (h=0, b=buf+1; h<8; ++h, ++b) {
            for (i=0; i<MAXLEN; ++i) {
                len = i;
                for (j=0; j<i; ++j) * (b+j)=0;

                /* these should all be equal */
                ref = c_jhash64 (b, len, (uint64)1);
                * (b+i)= (uint8)~0;
                * (b-1)= (uint8)~0;
                x = c_jhash64 (b, len, (uint64)1);
                y = c_jhash64 (b, len, (uint64)1);
                assert_false ( (ref != x) || (ref != y));
    #if 0
                print_error ("alignment error : %.8lx %.8lx %.8lx %ld %ld\n", ref, x, y, h, i);
    //  #endif
            }
        }
    }

    /***********************************************************
    ***********************************************************/
    static void check_c_jhash64_null_strings (void **state) {
        uint8 buf[1];
        uint64 h = 0;
        uint64 i = 0;
        uint64 t = 0;

        (void) state; /* unused */

        buf[0] = ~0;
        for (i=0, h=0; i<8; ++i) {
            t = h;
            h = c_jhash64 (buf, (uint64)0, h);
            assert_false (t == h);
    #if 0
            print_error ("0-byte-string check failed : t = %.8lx, h = %.8lx", t, h);
    //  #endif
        }
    }

    /***********************************************************
    ***********************************************************/
    int torture_run_tests (void) {
        struct CMUnitTest tests[] = {
                cmocka_unit_test (check_c_jhash_trials),
                cmocka_unit_test (check_c_jhash_alignment_problems),
                cmocka_unit_test (check_c_jhash_null_strings),
                cmocka_unit_test (check_c_jhash64_trials),
                cmocka_unit_test (check_c_jhash64_alignment_problems),
                cmocka_unit_test (check_c_jhash64_null_strings),
        }

        return cmocka_run_group_tests (tests, NULL, NULL);
    }

} // class CheckStdCJhash

} // namespace Testing
} // namespace Occ
