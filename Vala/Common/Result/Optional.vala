/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

template <typename T>
class Optional : Result<T, detail.OptionalNoErrorData> {

    /***********************************************************
    ***********************************************************/
    public using Result<T, detail.OptionalNoErrorData>.Result;

    /***********************************************************
    ***********************************************************/
    public Optional ()
        : Optional (detail.OptionalNoErrorData{}) {
    }
}