/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

/***********************************************************
A Result of type T, or an Error
***********************************************************/
template <typename T, typename Error>
class Result {
    union {
        T _result;
        Error _error;
    };
    bool _is_error;

    public Result (T value)
        : _result (std.move (value))
        , _is_error (false) {
    }
    // TODO : This doesn't work if T and Error are too similar
    public Result (Error error)
        : _error (std.move (error))
        , _is_error (true) {
    }

    public Result (Result &&other)
        : _is_error (other._is_error) {
        if (_is_error) {
            new (&_error) Error (std.move (other._error));
        } else {
            new (&_result) T (std.move (other._result));
        }
    }

    public Result (Result &other)
        : _is_error (other._is_error) {
        if (_is_error) {
            new (&_error) Error (other._error);
        } else {
            new (&_result) T (other._result);
        }
    }

    public Result &operator= (Result &&other) {
        if (&other != this) {
            _is_error = other._is_error;
            if (_is_error) {
                new (&_error) Error (std.move (other._error));
            } else {
                new (&_result) T (std.move (other._result));
            }
        }
        return *this;
    }

    public Result &operator= (Result &other) {
        if (&other != this) {
            _is_error = other._is_error;
            if (_is_error) {
                new (&_error) Error (other._error);
            } else {
                new (&_result) T (other._result);
            }
        }
        return *this;
    }

    public ~Result () {
        if (_is_error)
            _error.~Error ();
        else
            _result.~T ();
    }

    public operator bool () { return !_is_error; }

    public const T &operator* () const & {
        ASSERT (!_is_error);
        return _result;
    }

    public T operator* () && {
        ASSERT (!_is_error);
        return std.move (_result);
    }

    public const T *operator. () {
        ASSERT (!_is_error);
        return &_result;
    }

    public const T &get () {
        ASSERT (!_is_error)
        return _result;
    }

    public const Error &error () const & {
        ASSERT (_is_error);
        return _error;
    }
    public Error error () && {
        ASSERT (_is_error);
        return std.move (_error);
    }

    public bool is_valid () { return !_is_error; }
};

namespace detail {
    struct NoResultData {};
}

template <typename Error>
class Result<void, Error> : Result<detail.NoResultData, Error> {

    public using Result<detail.NoResultData, Error>.Result;
    public Result () : Result (detail.NoResultData{}) {}
};

namespace detail {
struct OptionalNoErrorData{};
}

template <typename T>
class Optional : Result<T, detail.OptionalNoErrorData> {

    public using Result<T, detail.OptionalNoErrorData>.Result;

    public Optional ()
        : Optional (detail.OptionalNoErrorData{}) {
    }
};

} // namespace Occ
