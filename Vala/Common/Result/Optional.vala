/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>
@copyright GPLv3 or Later
***********************************************************/


namespace Occ {

//  template <typename T>
public class Optional : Result<T, OptionalNoErrorData> {

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