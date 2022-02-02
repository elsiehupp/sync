
class Bio {

    public Bio ()
        : this.bio (BIO_new (BIO_s_mem ())) {
    }

    ~Bio () {
        BIO_free_all (this.bio);
    }

    public operator BIO* () {
        return this.bio;
    }

    //  private Q_DISABLE_COPY (Bio)

    private BIO* this.bio;
};