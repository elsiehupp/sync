namespace Occ {

/***********************************************************
@class Optional

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class Optional : Result<T, OptionalNoErrorData> {

    //  template <typename T>

    /***********************************************************
    ***********************************************************/
    //  public using Result<T, OptionalNoErrorData>.Result;

    /***********************************************************
    ***********************************************************/
    public Optional () {
        base (new OptionalNoErrorData ());
    }

} // class Optional

} // namespace Occ