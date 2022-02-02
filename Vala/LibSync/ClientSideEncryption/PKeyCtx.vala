
    class PKeyCtx {

        public PKeyCtx (int id, ENGINE *e = nullptr)
            : this.ctx (EVP_PKEY_CTX_new_id (id, e)) {
        }

        ~PKeyCtx () {
            EVP_PKEY_CTX_free (this.ctx);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a `for_key` static function that returns
        // an instance of this class
        public PKeyCtx (PKeyCtx&& other) {
            std.swap (this.ctx, other._ctx);
        }

        public PKeyCtx& operator= (PKeyCtx&& other) = delete;

        public static PKeyCtx for_key (EVP_PKEY *pkey, ENGINE *e = nullptr) {
            PKeyCtx ctx;
            ctx._ctx = EVP_PKEY_CTX_new (pkey, e);
            return ctx;
        }

        public operator EVP_PKEY_CTX* () {
            return this.ctx;
        }

        //  private Q_DISABLE_COPY (PKeyCtx)

        private PKeyCtx () = default;

        private EVP_PKEY_CTX* this.ctx = nullptr;
    };