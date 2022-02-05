/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
A Result of type T, or an Error
***********************************************************/
template <typename T, typename Error>
class Result {
    union {
        T this.result;
        Error this.error;
    }
    bool this.is_error;

    /***********************************************************
    ***********************************************************/
    public Result (T value)
        : this.result (std.move (value))
        this.is_error (false) {
    }


    // TODO : This doesn't work if T and Error are too similar
    public Result (Error error)
        : this.error (std.move (error))
        this.is_error (true) {
    }


    /***********************************************************
    ***********************************************************/
    public Result (Result &&other)
        : this.is_error (other.is_error) {
        if (this.is_error) {
            new (&this.error) Error (std.move (other.error));
        } else {
            new (&this.result) T (std.move (other.result));
        }
    }


    /***********************************************************
    ***********************************************************/
    public Result (Result other)
        : this.is_error (other.is_error) {
        if (this.is_error) {
            new (&this.error) Error (other.error);
        } else {
            new (&this.result) T (other.result);
        }
    }


    /***********************************************************
    ***********************************************************/
    public Result operator= (Result &&other) {
        if (&other != this) {
            this.is_error = other.is_error;
            if (this.is_error) {
                new (&this.error) Error (std.move (other.error));
            } else {
                new (&this.result) T (std.move (other.result));
            }
        }
        return this;
    }


    /***********************************************************
    ***********************************************************/
    public Result operator= (Result other) {
        if (&other != this) {
            this.is_error = other.is_error;
            if (this.is_error) {
                new (&this.error) Error (other.error);
            } else {
                new (&this.result) T (other.result);
            }
        }
        return this;
    }


    ~Result () {
        if (this.is_error)
            this.error.~Error ();
        else
            this.result.~T ();
    }


    /***********************************************************
    ***********************************************************/
    public to_bool () {
        return !this.is_error;
    }


    /***********************************************************
    ***********************************************************/
    public const T operator* () & {
        //  ASSERT (!this.is_error);
        return this.result;
    }


    /***********************************************************
    ***********************************************************/
    public T operator* () && {
        //  ASSERT (!this.is_error);
        return std.move (this.result);
    }


    /***********************************************************
    ***********************************************************/
    public const T *operator. () {
        //  ASSERT (!this.is_error);
        return this.result;
    }


    /***********************************************************
    ***********************************************************/
    public const T get () {
        //  ASSERT (!this.is_error)
        return this.result;
    }


    /***********************************************************
    ***********************************************************/
    public const Error error () & {
        //  ASSERT (this.is_error);
        return this.error;
    }


    /***********************************************************
    ***********************************************************/
    public Error error () && {
        //  ASSERT (this.is_error);
        return std.move (this.error);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_valid () {
        return !this.is_error;
    }
}

namespace detail {
    struct NoResultData {};
}

template <typename Error>
class Result<void, Error> : Result<detail.NoResultData, Error> {

    /***********************************************************
    ***********************************************************/
    public using Result<detail.NoResultData, Error>.Result;
    public Result () : Result (detail.NoResultData{}) {}
}

namespace detail {
struct OptionalNoErrorData{};
}


} // namespace Occ
