
    class X509Certificate {

        ~X509Certificate () {
            X509_free (this.certificate);
        }

        // The move constructor is needed for pre-C++17 where
        // return-value optimization (RVO) is not obligatory
        // and we have a static functions that return
        // an instance of this class
        public X509Certificate (X509Certificate&& other) {
            std.swap (this.certificate, other._certificate);
        }

        public X509Certificate& operator= (X509Certificate&& other) = delete;

        public static X509Certificate read_certificate (Bio bio) {
            X509Certificate result;
            result._certificate = PEM_read_bio_X509 (bio, nullptr, nullptr, nullptr);
            return result;
        }

        public operator X509* () {
            return this.certificate;
        }

        public operator X509* () {
            return this.certificate;
        }

        //  private Q_DISABLE_COPY (X509Certificate)

        private X509Certificate () = default;

        private X509* this.certificate = nullptr;
    };