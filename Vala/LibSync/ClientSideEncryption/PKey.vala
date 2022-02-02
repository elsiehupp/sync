
    class PKey {

        ~PKey () {
            EVP_PKEY_free (this.pkey);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a static functions that return
        // an instance of this class
        public PKey (PKey&& other) {
            std.swap (this.pkey, other._pkey);
        }

        public PKey& operator= (PKey&& other) = delete;

        public static PKey read_public_key (Bio bio) {
            PKey result;
            result._pkey = PEM_read_bio_PUBKEY (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public static PKey read_private_key (Bio bio) {
            PKey result;
            result._pkey = PEM_read_bio_Private_key (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public static PKey generate (PKeyCtx& ctx) {
            PKey result;
            if (EVP_PKEY_keygen (ctx, result._pkey) <= 0) {
                result._pkey = nullptr;
            }
            return result;
        }

        public operator EVP_PKEY* () {
            return this.pkey;
        }

        public operator EVP_PKEY* () {
            return this.pkey;
        }

        //  private Q_DISABLE_COPY (PKey)

        private PKey () = default;

        private EVP_PKEY* this.pkey = nullptr;
    };