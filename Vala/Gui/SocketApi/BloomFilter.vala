/***********************************************************
Copyright (C) by Dominik Schmidt <dev@dominik-schmidt.de>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

class Bloom_filter {
    // Initialize with m=1024 bits and k=2 (high and low 16 bits of a q_hash).
    // For a client navigating in less than 100 directories, this gives us a probability less than
    // (1-e^ (-2*100/1024))^2 = 0.03147872136 false positives.
    const static int Num_bits = 1024;

    public Bloom_filter ()
        : hash_bits (Num_bits) {
    }

    public void store_hash (uint32 hash) {
        hash_bits.bit ( (hash & 0x_f_f_f_f) % Num_bits); // NOLINT it's uint32 all the way and the modulo puts us back in the 0..1023 range
        hash_bits.bit ( (hash >> 16) % Num_bits); // NOLINT
    }
    public bool is_hash_maybe_stored (uint32 hash) {
        return hash_bits.test_bit ( (hash & 0x_f_f_f_f) % Num_bits) // NOLINT
            && hash_bits.test_bit ( (hash >> 16) % Num_bits); // NOLINT
    }


    private QBit_array hash_bits;
};