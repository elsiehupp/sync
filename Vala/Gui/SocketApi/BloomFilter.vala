/***********************************************************
@author Dominik Schmidt <dev@dominik-schmidt.de>
@author Klaas Freitag <freitag@owncloud.com>
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class BloomFilter : Glib.Object {

    /***********************************************************
    Initialize with m=1024 bits and k=2 (high and low 16 bits of a q_hash).
    For a client navigating in less than 100 directories, this gives us a probability less than
    (1-e^(-2*100/1024))^2 = 0.03147872136 false positives.
    ***********************************************************/
    const static int NUMBER_OF_BITS = 1024;

    private GLib.BitArray hash_bits;

    /***********************************************************
    ***********************************************************/
    public BloomFilter () {
        hash_bits (NUMBER_OF_BITS) {
    }


    /***********************************************************
    ***********************************************************/
    public void store_hash (uint32 hash) {
        hash_bits.bit ( (hash & 0x_f_f_f_f) % NUMBER_OF_BITS); // NOLINT it's uint32 all the way and the modulo puts us back in the 0..1023 range
        hash_bits.bit ( (hash >> 16) % NUMBER_OF_BITS); // NOLINT
    }


    /***********************************************************
    ***********************************************************/
    public bool is_hash_maybe_stored (uint32 hash) {
        return hash_bits.test_bit ( (hash & 0x_f_f_f_f) % NUMBER_OF_BITS) // NOLINT
            && hash_bits.test_bit ( (hash >> 16) % NUMBER_OF_BITS); // NOLINT
    }

} // class BloomFilter

} // namespace Ui
} // namespace Occ
