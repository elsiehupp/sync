namespace Occ {
namespace Common {

/***********************************************************
@class JenkinsHash

@brief Interface of the cynapses jhash implementation

@author 1997 Bob Jenkins <bob_jenkins@burtleburtle.

@copyright lookup8.c, by Bob Jenkins, January 4 1997, Public Domain.
hash (), hash2 (), hash3, and this.c_mix () are externally useful
Routines to test the hash are included if SELF_TEST is defined.
You can use this free for any purpose. It has no warranty.

See http://burtleburtle.net/bob/hash/evahash.html
***********************************************************/
public class JenkinsHash : GLib.Object {

    /***********************************************************
    c_mix -- Mix 3 32-bit values reversibly.

    For every delta with one or two bit set, and the deltas of all three
    high bits or all three low bits, whether the or
    is almost all zero or is uniformly distributed,
    If this.c_mix () is run forward or backward, a
    have at least 1/4 probability of changing.
    If this.c_mix () is run forward, every bit of c will change between 1/
    2/3 of the time.    (Well, 22/100 and 78/100 for some 2-bit deltas.)
    this.c_mix () was built out of 36 single-cycle latency inst
    structure t
            a -= b;
            a -= c; x = (c>
            b -= c; a ^= x;
            b -= a; x = (a<
            c -= a; b ^= x;
            c -= b
            ...

    Unfortunately, superscalar Pentiums and Sparcs can't take advantage
    of that parallelism.    They've also turned some of those single-cycl
    latency instructions into multi-cycle latency instructions.    Still,
    this is the fastest good hash I could find.    There were about 2^^68
    to choose from.    I only looked at a billion or so.
    ***********************************************************/
    public static int c_mix (uint32 a, uint32 b, uint32 c) {
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>13);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<8);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>13);
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>12);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<16);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>5);
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>3);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<10);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>15);
    }

    /***********************************************************
    this.c_mix64 -- Mix 3 64-bit values reversibly.

    this.c_mix64 () takes 48 machine instructions, but only 24 cycles on a
    machine (like Intel's new MMX
    registers for 4.2 parallelism.
    All 1-bit deltas, all 2-bit deltas, all deltas composed of top bits
    (a,b,c), and all deltas of bottom bits were tested.    All deltas w
    tested both on random keys and on keys that were nearly all zero.
    These deltas all cause every bit of c to change between 1/3 and
    of the time (well, only 113/400 to 287/400 of the time for some
    2-bit delta).    These deltas all cause at least 80 bits to change
    among (a,b,c) w
    is reversible).
    This implies that a hash using this.c_mix64 has no funnels.    There
    characteristics with 3-bit deltas or bigger, I didn't test for
    those.
    ***********************************************************/
    public static int c_mix64 (uint64 a, uint64 b, uint64 c) {
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>43);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<9);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>8);
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>38);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<23);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>5);
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>35);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<49);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>11);
        (a) -= (b); (a) -= (c); (a) ^= ( (c)>>12);
        (b) -= (c); (b) -= (a); (b) ^= ( (a)<<18);
        (c) -= (a); (c) -= (b); (c) ^= ( (b)>>22);
    }

    /***********************************************************
    @brief hash a variable-length key into a 32-bit value

    The best hash table sizes are powers of 2. There is no need
    to mod a prime (mod is sooo slow!). If you need less than 3
    use a bitmask. For example:
        h = (h & hashmask (10));
    In which case, the hash table should have hashsize (10)
    elements.

    Use for hash table lookup, or anything where one collision
    in 2^32 is acceptable. Do NOT use for cryptographic purposes.

    @param key              The key (the unaligned variable-
                            length array of bytes).

    @param length           The length of the key, counting by
                            bytes.

    @param initial_value    Initial value, can be any 4-byte value.

    @return                 Returns a 32-bit value. Every bit of
                            the key affects ever of the return
                            value. Every 1-bit and 2-bit delta
                            achieves avalanche. About 36+6len
                            instructions.
    ***********************************************************/
    public static uint32 c_jhash (uint8 *key, uint32 length, uint32 initial_value) {
        uint32 a = 0;
        uint32 b = 0;
        uint32 c = 0;
        uint32 len = 0;

        /* Set up the internal state */
        len = length;


        a = (uint32)0x9e3779b9; /* the golden ratio; an arbitrary value */
        b = a;
        c = initial_value; /* the previous hash value */

        while (len >= 12) {
                a += (key[0] + ( (uint32)key[1]<<8) + ( (uint32)key[2]<<16) + ( (uint32)key[3]<<24));
                b += (key[4] + ( (uint32)key[5]<<8) + ( (uint32)key[6]<<16) + ( (uint32)key[7]<<24));
                c += (key[8] + ( (uint32)key[9]<<8) + ( (uint32)key[10]<<16)+ ( (uint32)key[11]<<24));
                c_mix (a,b,c);
                key += 12; len -= 12;
        }

        /* handle the last 11 bytes */
        c += length;
        /* all the case statements fall through */
        switch (len) {
            case 11 : c+= ( (uint32)key[10]<<24);
            case 10 : c+= ( (uint32)key[9]<<16);
            case 9 : c+= ( (uint32)key[8]<<8);
            /* the first byte of c is reserved for the length */
            case 8 : b+= ( (uint32)key[7]<<24);
            case 7 : b+= ( (uint32)key[6]<<16);
            case 6 : b+= ( (uint32)key[5]<<8);
            case 5 : b+=key[4];
            case 4 : a+= ( (uint32)key[3]<<24);
            case 3 : a+= ( (uint32)key[2]<<16);
            case 2 : a+= ( (uint32)key[1]<<8);
            case 1 : a+=key[0];
            /* case 0 : nothing left to add */
        }
        c_mix (a, b, c);

        return c;
    }

    /***********************************************************
    @brief hash a variable-length key into a 64-bit value

    The best hash table sizes are powers of 2. There is no need
    to mod a prime (mod is sooo slow!). If you need less than 6
    use a bitmask. For example:
        h = (h & hashmask (10));
    In which case, the hash table should have hashsize (10)
    elements.

    Use for hash table lookup, or anything where one collision
    in 2^^64 is acceptable. Do NOT use for cryptographic
    purposes.

    @param key             The key (the unaligned variable-length array of bytes
    @param length          The length of the key, counting by bytes.
    @param initial_value   Initial value, can be any 8-byte value.

    @return         A 64-bit value. Every bit of the key affects every bit of
                        the return value.    No funnels.    Every 1-bit and 2-bit delta
                        achieves avalanche. About 41+5len instructions.
    ***********************************************************/
    public static uint64 c_jhash64 (uint8 *key, uint64 length, uint64 initial_value) {
        uint64 a = 0;
        uint64 b = 0;
        uint64 c = 0;
        uint64 len = 0;

        /* Set up the internal state */
        len = length;
        a = b = initial_value; /* the previous hash value */
        c = 0x9e3779b97f4a7c13LL; /* the golden ratio; an arbitrary value */

        /* handle most of the key */
        while (len >= 24) {
            a += (key[0]              + ( (uint64)key[ 1]<< 8) + ( (uint64)key[ 2]<<16) + ( (uint64)key[ 3]<<24)
            + ( (uint64)key[4 ]<<32)  + ( (uint64)key[ 5]<<40) + ( (uint64)key[ 6]<<48) + ( (uint64)key[ 7]<<56));
            b += (key[8]              + ( (uint64)key[ 9]<< 8) + ( (uint64)key[10]<<16) + ( (uint64)key[11]<<24)
            + ( (uint64)key[12]<<32)  + ( (uint64)key[13]<<40) + ( (uint64)key[14]<<48) + ( (uint64)key[15]<<56));
            c += (key[16]             + ( (uint64)key[17]<< 8) + ( (uint64)key[18]<<16) + ( (uint64)key[19]<<24)
            + ( (uint64)key[20]<<32)  + ( (uint64)key[21]<<40) + ( (uint64)key[22]<<48) + ( (uint64)key[23]<<56));
            c_mix64 (a, b, c);
            key += 24; len -= 24;
        }

        /* handle the last 23 bytes */
        c += length;
        switch (len) {
            /***********************************************************
            These cases intentionally fall through.
            ***********************************************************/
            case 23 : c+= ( (uint64)key[22]<<56);
            case 22 : c+= ( (uint64)key[21]<<48);
            case 21 : c+= ( (uint64)key[20]<<40);
            case 20 : c+= ( (uint64)key[19]<<32);
            case 19 : c+= ( (uint64)key[18]<<24);
            case 18 : c+= ( (uint64)key[17]<<16);
            case 17 : c+= ( (uint64)key[16]<<8); 
            /* the first byte of c is reserved for the length */
            case 16 : b+= ( (uint64)key[15]<<56);
            case 15 : b+= ( (uint64)key[14]<<48);
            case 14 : b+= ( (uint64)key[13]<<40);
            case 13 : b+= ( (uint64)key[12]<<32);
            case 12 : b+= ( (uint64)key[11]<<24);
            case 11 : b+= ( (uint64)key[10]<<16);
            case 10 : b+= ( (uint64)key[ 9]<<8); 
            case  9 : b+= ( (uint64)key[ 8]);    
            case  8 : a+= ( (uint64)key[ 7]<<56);
            case  7 : a+= ( (uint64)key[ 6]<<48);
            case  6 : a+= ( (uint64)key[ 5]<<40);
            case  5 : a+= ( (uint64)key[ 4]<<32);
            case  4 : a+= ( (uint64)key[ 3]<<24);
            case  3 : a+= ( (uint64)key[ 2]<<16);
            case  2 : a+= ( (uint64)key[ 1]<<8); 
            case  1 : a+= ( (uint64)key[ 0]);
            /* case 0 : nothing left to add */
        }
        c_mix64 (a, b, c);

        return c;
    }


    private static int c_hashsize (int n) {
        return ((uint8) 1 << (n));
    }


    private static int c_hashmask (int n) {
        return xhashsize (n) - 1;
    }

} // class JenkinsHash

} // namespace Common
} // namespace Occ

