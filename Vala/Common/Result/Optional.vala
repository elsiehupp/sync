/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

//  template <typename T>
class Optional : Result<T, OptionalNoErrorData> {

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