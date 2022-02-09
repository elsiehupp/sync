/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
A Result of type T, or an Error
***********************************************************/
class Result<T> {

    struct NoResultData {}
    struct OptionalNoErrorData {}

    T result {
        public get {
            //  ASSERT (!this.is_error)
            return this.result;
        }
    }
    Error error {
        public get {
            //  ASSERT (this.is_error);
            return this.error;
        }
    }
    bool is_error;

    /***********************************************************
    ***********************************************************/
    public Result.from_result (T value) {
        this.result = std.move (value);
        this.is_error = false;
    }



    /***********************************************************
    TODO: This doesn't work if T and Error are too similar
    ***********************************************************/
    public Result.from_error (Error error) {
        this.error = std.move (error);
        this.is_error = true;
    }


    /***********************************************************
    ***********************************************************/
    //  public Result.from_other (Result other) {
    //      this.is_error = other.is_error;
    //      if (this.is_error) {
    //          new (&this.error) Error (std.move (other.error));
    //      } else {
    //          new (&this.result) T (std.move (other.result));
    //      }
    //  }


    /***********************************************************
    ***********************************************************/
    public Result.from_other (Result other) {
        this.is_error = other.is_error;
        if (this.is_error) {
            this.error = other.error;
        } else {
            this.result = other.result;
        }
    }


    /***********************************************************
    ***********************************************************/
    //  public Result operator= (Result &&other) {
    //      if (&other != this) {
    //          this.is_error = other.is_error;
    //          if (this.is_error) {
    //              new (&this.error) Error (std.move (other.error));
    //          } else {
    //              new (&this.result) T (std.move (other.result));
    //          }
    //      }
    //      return this;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public Result operator= (Result other) {
    //      if (&other != this) {
    //          this.is_error = other.is_error;
    //          if (this.is_error) {
    //              new (&this.error) Error (other.error);
    //          } else {
    //              new (&this.result) T (other.result);
    //          }
    //      }
    //      return this;
    //  }


    ~Result () {
        if (this.is_error) {
            delete (this.error);
        } else {
            delete (this.result);
        }
    }


    /***********************************************************
    ***********************************************************/
    public bool to_bool () {
        return !this.is_error;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_valid () {
        return !this.is_error;
    }


    /***********************************************************
    ***********************************************************/
    //  public const T operator* () & {
    //      //  ASSERT (!this.is_error);
    //      return this.result;
    //  }


    /***********************************************************
    ***********************************************************/
    //  public T operator* () && {
    //      //  ASSERT (!this.is_error);
    //      return std.move (this.result);
    //  }


    /***********************************************************
    ***********************************************************/
    //  public const T *operator-> () {
    //      //  ASSERT (!this.is_error);
    //      return this.result;
    //  }

    /***********************************************************
    ***********************************************************/
    //  public Error error () && {
    //      //  ASSERT (this.is_error);
    //      return std.move (this.error);
    //  }

} // class Result<T>

//  class Result<void, Error> : Result<detail.NoResultData, Error> {
//
//      /***********************************************************
//      ***********************************************************/
//      public using Result<detail.NoResultData, Error>.Result;
//      public Result () : Result (detail.NoResultData{}) {}
//  }

} // namespace Occ